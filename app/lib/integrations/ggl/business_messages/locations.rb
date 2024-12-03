# frozen_string_literal: true

# app/lib/integrations/ggl/business_messages/locations.rb
module Integrations
  module Ggl
    module BusinessMessages
      # Google Locations methods called by Google Messages class
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Locations
        # create a Google Business Messages Location for a Brand/Agent
        # ggl_client.business_messages_create_location(brand_id, agent_id, place_id)
        # (req) brand_id: (String)
        # (req) agent_id: (String)
        # (req) place_id: (String)
        def business_messages_create_location(brand_id, agent_id, place_id)
          reset_attributes
          @result = {}

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          elsif agent_id.blank?
            @message = 'Agent ID required.'
            return @result
          elsif place_id.blank?
            @message = 'Place ID required.'
            return @result
          end

          body = {
            placeId:       place_id,
            agent:         agent_id,
            defaultLocale: 'en'
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Locations.LocationCreate',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{locations_base_url}/#{locations_base_version}/#{brand_id}/locations"
          )

          @result
        end

        def business_messages_delete_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Locations.BusinessMessagesLocationDelete',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{locations_base_url}/#{locations_base_version}/#{location_id}"
          )

          @result
        end

        # Launch a Google Business Messages Location
        # ggl_client.business_messages_launch_location(location_id)
        # (req) location_id:    (String)
        def business_messages_launch_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesLaunchLocation',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{location_id}:requestLaunch"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/locations/bbb61714-818f-46c0-a38a-5dbfc6fd6a8f/launch",
        #   :launchState=>"LAUNCH_STATE_LAUNCHED"
        # }

        # Check launch status of a Google Business Messages Location
        # ggl_client.business_messages_launched_location(location_id)
        # (req) agent_id: (String)
        def business_messages_launched_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesLaunchedLocation',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{location_id}/launch"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/locations/bbb61714-818f-46c0-a38a-5dbfc6fd6a8f/launch",
        #   :launchState=>"LAUNCH_STATE_LAUNCHED"
        # }

        def business_messages_location(location_id)
          reset_attributes
          @result = []

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Locations.BusinessMessagesLocation',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{locations_base_url}/#{locations_base_version}/#{location_id}"
          )

          @result
        end

        # Locations owned by a Brand
        # ggl_client.brands
        def business_messages_locations(brand_id)
          reset_attributes
          @result = {}

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Locations.BusinessMessagesLocations',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{locations_base_url}/#{locations_base_version}/#{brand_id}/locations"
          )

          @result = @result&.dig(:locations) || {}
        end

        # Unlaunch a Google Business Messages Location
        # ggl_client.business_messages_unlaunch_location(location_id)
        # (req) location_id:    (String)
        def business_messages_unlaunch_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          body = { launchState: 'LAUNCH_STATE_UNLAUNCHED' }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesUnlaunchLocation',
            method:                'patch',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{location_id}/launch"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/locations/bbb61714-818f-46c0-a38a-5dbfc6fd6a8f/launch",
        #   :launchState=>"LAUNCH_STATE_UNLAUNCHED"
        # }

        def business_messages_update_location(brand_id, location_id, name)
          reset_attributes
          @result = {}

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          elsif location_id.blank?
            @message = 'Location ID required.'
            return @result
          elsif name.blank?
            @message = 'New name required.'
            return @result
          end

          body = { name: }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Locations.BusinessMessagesLocationUpdate',
            method:                'patch',
            params:                { readMask: self.location_read_mask },
            default_result:        @result,
            url:                   "#{locations_base_url}/#{locations_base_version}/#{brand_id}/#{location_id}"
          )

          @result
        end

        # Check verification of a Google BusinessMessages Location
        # ggl_client.business_messages_verified_location(location_id)
        # (req) location_id: (String)
        # verificationStates: VERIFICATION_STATE_UNSPECIFIED / VERIFICATION_STATE_UNVERIFIED / VERIFICATION_STATE_PENDING / VERIFICATION_STATE_VERIFIED / VERIFICATION_STATE_SUSPENDED_IN_GMB
        def business_messages_verified_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesVerifiedLocation',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{location_id}/verification"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/locations/bbb61714-818f-46c0-a38a-5dbfc6fd6a8f/verification",
        #   :verificationState=>"VERIFICATION_STATE_VERIFIED"
        # }

        # Verify a Google Business Messages Location
        # ggl_client.business_messages_verify_location(location_id)
        # (req) location_id: (String)
        # verificationStates: VERIFICATION_STATE_UNSPECIFIED / VERIFICATION_STATE_UNVERIFIED / VERIFICATION_STATE_PENDING / VERIFICATION_STATE_VERIFIED / VERIFICATION_STATE_SUSPENDED_IN_GMB
        def business_messages_verify_location(location_id)
          reset_attributes
          @result = {}

          if location_id.blank?
            @message = 'Location ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Agents.BusinessMessagesVerifyLocation',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{agents_base_url}/#{agents_base_version}/#{location_id}:requestVerification"
          )

          @result
        end
        # {
        #   :name=>"brands/85851e0e-8406-4812-8d15-53feecfa3b84/locations/bbb61714-818f-46c0-a38a-5dbfc6fd6a8f/verification",
        #   :verificationState=>"VERIFICATION_STATE_VERIFIED"
        # }

        private

        def location_read_mask
          'name'
        end

        def locations_base_url
          'https://businesscommunications.googleapis.com'
        end

        def locations_base_version
          'v1'
        end
      end
    end
  end
end
