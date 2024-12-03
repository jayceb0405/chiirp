# frozen_string_literal: true

# app/controllers/integrations/servicetitan/events_controller.rb
module Integrations
  module Servicetitan
    class EventsController < Servicetitan::IntegrationsController
      # (GET) refresh ST business units
      # /integrations/servicetitan/events/refresh_business_units
      # integrations_servicetitan_events_refresh_business_units_path
      # integrations_servicetitan_events_refresh_business_units_url
      def refresh_business_units
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_business_units
      end

      # (GET) refresh ST call reasons
      # /integrations/servicetitan/events/refresh_call_reasons
      # integrations_servicetitan_events_refresh_call_reasons_path
      # integrations_servicetitan_events_refresh_call_reasons_url
      def refresh_call_reasons
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_call_reasons
      end

      # (GET) refresh ST campaigns
      # /integrations/servicetitan/events/refresh_campaigns
      # integrations_servicetitan_events_refresh_campaigns_path
      # integrations_servicetitan_events_refresh_campaigns_url
      def refresh_campaigns
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_campaigns
      end

      # (GET) refresh ST job cancel reasons
      # /integrations/servicetitan/events/refresh_job_cancel_reasons
      # integrations_servicetitan_events_refresh_job_cancel_reasons_path
      # integrations_servicetitan_events_refresh_job_cancel_reasons_url
      def refresh_job_cancel_reasons
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_job_cancel_reasons
      end

      # (GET) refresh ST job types
      # /integrations/servicetitan/events/refresh_job_types
      # integrations_servicetitan_events_refresh_job_types_path
      # integrations_servicetitan_events_refresh_job_types_url
      def refresh_job_types
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_job_types
      end

      # (GET) refresh ST membership types
      # /integrations/servicetitan/events/refresh_membership_types
      # integrations_servicetitan_events_refresh_membership_types_path
      # integrations_servicetitan_events_refresh_membership_types_url
      def refresh_membership_types
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_membership_types
      end

      # (GET) refresh ST tag ids
      # /integrations/servicetitan/events/refresh_tag_ids
      # integrations_servicetitan_events_refresh_tag_ids_path
      # integrations_servicetitan_events_refresh_tag_ids_url
      def refresh_tag_ids
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_tag_types
      end

      # (GET) refresh ST technicians
      # /integrations/servicetitan/events/refresh_technicians
      # integrations_servicetitan_events_refresh_technicians_path
      # integrations_servicetitan_events_refresh_technicians_url
      def refresh_technicians
        @event_id = params.dig(:event_id)
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_technicians
      end

      # (GET) show JobComplete actions
      # /integrations/servicetitan/events
      # integrations_servicetitan_events_path
      # integrations_servicetitan_events_url
      def show
        initialize_event_cookie
      end

      private

      def initialize_event_cookie
        cookie_hash = {}

        @client_api_integration.events.each_key do |event_id|
          cookie_hash[event_id] = 'false'
        end

        RedisCloud.redis.setex("user:#{current_user.id}:edit_servicetitan_event_shown", 1800, cookie_hash.to_json)
      end
    end
  end
end
