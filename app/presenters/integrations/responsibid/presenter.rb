# frozen_string_literal: true

# app/presenters/integrations/responsibid/presenter.rb
module Integrations
  module Responsibid
    # variables required by ResponsiBid views
    class Presenter
      attr_accessor :webhooks
      attr_reader   :client, :client_api_integration, :webhook, :webhook_event, :webhook_event_id, :webhook_events, :webhook_object

      # Integrations::Responsibid::Presenter.new(client_api_integration: ClientApiIntegration)
      def initialize(args = {})
        self.client_api_integration = args.dig(:client_api_integration)
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new(target: 'responsibid')
                                  end

        @client                    = @client_api_integration.client
        @webhook                   = nil
        @webhook_event             = nil
        @webhook_event_id          = nil
        @webhook_events            = []
        @webhook_object            = ''
        @webhooks                  = self.client_api_integration.webhooks.deep_symbolize_keys
      end

      def form_method
        self.webhook_event_id.present? ? :patch : :post
      end

      def form_url
        self.webhook_event_id.present? ? Rails.application.routes.url_helpers.integrations_responsibid_webhook_path(self.webhook_event_id) : Rails.application.routes.url_helpers.integrations_responsibid_webhooks_path
      end

      def webhook_count
        webhook_count = 0

        client_api_integration.webhooks.keys.each do |key|
          webhook_count += client_api_integration.webhooks[key].length
        end

        webhook_count
      end

      def webhook_event=(webhook_event)
        @webhook_event    = webhook_event&.deep_symbolize_keys
        @webhook_event_id = @webhook_event&.dig(:event_id).to_s
        @webhook          = Integration::Responsibid.webhook_by_id(self.client_api_integration.webhooks, @webhook_event_id)
        @webhook_events   = @webhook.values.flatten
        @webhook_object   = @webhook.keys.first.to_s
      end

      def webhook_event_campaign
        id = self.webhook_event.dig(:actions, :campaign_id).to_i
        id.positive? ? Campaign.find_by(client_id: self.client_api_integration.client_id, id:) : nil
      end

      def webhook_event_group
        id = self.webhook_event.dig(:actions, :group_id).to_i
        id.positive? ? Group.find_by(client_id: self.client_api_integration.client_id, id:) : nil
      end

      def webhook_event_new
        (self.webhook_event.dig(:criteria, :event_new) || false).to_bool
      end

      def webhook_event_stage
        id = self.webhook_event.dig(:actions, :stage_id).to_i
        id.positive? ? Stage.for_client(self.client_api_integration.client_id).find_by(id:) : nil
      end

      def webhook_event_stop_campaigns
        return ['All Campaigns'] if self.webhook_event_stop_campaign_ids&.include?(0)

        Campaign.where(client_id: self.client_api_integration.client_id, id: self.webhook_event_stop_campaign_ids).pluck(:name)
      end

      def webhook_event_stop_campaign_ids
        self.webhook_event.dig(:actions, :stop_campaign_ids)&.compact_blank
      end

      def webhook_event_tag
        id = self.webhook_event.dig(:actions, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: self.client_api_integration.client_id, id:) : nil
      end

      def webhook_event_updated
        (self.webhook_event.dig(:criteria, :event_updated) || false).to_bool
      end

      def webhook_event_version
        (self.webhook_event.dig(:version) || 2).to_i
      end

      def webhook_events_array
        Integration::Responsibid.webhooks(self.client_api_integration.custom_events).map { |w| [w.dig(:name).to_s, w.dig(:event).to_s] }
      end

      def webhook_name
        (Integration::Responsibid.webhooks(self.client_api_integration.custom_events).find { |w| w[:event] == self.webhook_object } || { name: 'unknown' }).dig(:name).to_s
      end
    end
  end
end
