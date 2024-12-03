# frozen_string_literal: true

# app/presenters/integrations/outreach/presenter.rb
module Integrations
  module Outreach
    # variables required by Outreach views
    class Presenter
      attr_reader :outreach_webhook, :client_api_integration

      def initialize(args = {})
        self.client_api_integration = args.dig(:client_api_integration)
      end

      def available_call_dispositions_array
        self.outreach_client.call_dispositions.map { |cd| [cd.dig(:attributes, :name).to_s, cd.dig(:id).to_i] }
      end

      def available_webhooks_array
        [
          ['Prospect/Created', 'prospect_created'],
          ['Prospect/Updated', 'prospect_updated'],
          ['Call/Created', 'call_created']
        ]
      end

      def campaigns_allowed
        self.client_api_integration.client.campaigns_count.positive?
      end

      def client
        @client || @client_api_integration.client
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new
                                  end

        @client                     = nil
        @outreach_call_dispositions = nil
        @outreach_client            = nil
        @outreach_users             = nil
        @outreach_webhook           = {}
        @outreach_webhooks          = nil
        @webhook_actions            = nil
      end

      def connection_valid?
        @client_api_integration.valid_outreach_token?
      end

      def form_method
        @outreach_webhook&.dig(:id).to_i.positive? ? :patch : :post
      end

      def form_url
        @outreach_webhook&.dig(:id).to_i.positive? ? Rails.application.routes.url_helpers.integrations_outreach_webhook_path(@outreach_webhook&.dig(:id).to_i) : Rails.application.routes.url_helpers.integrations_outreach_webhooks_path
      end

      def groups_allowed
        self.client_api_integration.client.groups_count.positive?
      end

      def outreach_client
        @outreach_client ||= Integrations::OutReach.new(@client_api_integration.token, @client_api_integration.refresh_token, @client_api_integration.expires_at, @client_api_integration.client.tenant)
      end

      def outreach_users
        @outreach_users ||= self.outreach_client.users.map { |u| { id: u.dig(:id).to_i, name: u.dig(:attributes, :name).to_s } }
      end

      def outreach_webhook=(id)
        @outreach_webhook = self.outreach_webhooks.find { |webhook| webhook.dig(:id).to_i == id } || {}
      end

      def outreach_webhooks
        @outreach_webhooks || @outreach_webhooks = self.outreach_client.webhooks
      end

      def stages_allowed
        self.client_api_integration.client.stages_count.positive?
      end

      def webhook_actions
        @webhook_actions || @client_api_integration.webhook_actions.map(&:deep_symbolize_keys).find { |webhook| webhook.dig(:id).to_i == @outreach_webhook.dig(:id).to_i } || {}
      end

      def webhook_campaign
        id = self.webhook_actions.dig(:actions, :campaign_id).to_i
        id.positive? ? Campaign.find_by(client_id: self.client.id, id:) : nil
      end

      def webhook_group
        id = self.webhook_actions.dig(:actions, :group_id).to_i
        id.positive? ? Group.find_by(client_id: self.client.id, id:) : nil
      end

      def webhook_stage
        id = self.webhook_actions.dig(:actions, :stage_id).to_i
        id.positive? ? Stage.for_client(self.client.id).find_by(id:) : nil
      end

      def webhook_stop_campaigns
        return ['All Campaigns'] if self.webhook_stop_campaign_ids&.include?(0)

        Campaign.where(client_id: @client.id, id: self.webhook_stop_campaign_ids).pluck(:name)
      end

      def webhook_stop_campaign_ids
        self.webhook_actions.dig(:actions, :stop_campaign_ids)&.compact_blank
      end

      def webhook_tag
        id = self.webhook_actions.dig(:actions, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: self.client.id, id:) : nil
      end
    end
  end
end
