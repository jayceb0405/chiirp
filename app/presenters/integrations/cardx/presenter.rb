# frozen_string_literal: true

# app/presenters/integrations/cardx/presenter.rb
module Integrations
  module Cardx
    class Presenter < BasePresenter
      attr_reader :account, :events, :event

      # Integrations::Cardx::Presenter.new(client_api_integration: @client_api_integration)
      #   (req) client_api_integration: (ClientApiIntegration) or (Integer)

      def client_api_integration=(client_api_integration)
        super
        @cx_client = Integrations::CardX::Base.new(client_api_integration.account)
        @account   = client_api_integration.account
        @events    = client_api_integration.events
      end

      def campaigns_allowed
        @client.campaigns_count.positive?
      end

      def cardx_js_url
        Rails.env.production? ? 'https://lightbox.cardx.com/v1/lightbox.min.js' : 'https://test.lightbox.cardx.com/v1/lightbox.min.js'
      end

      def event=(event)
        @event = event&.deep_symbolize_keys
      end

      def event_campaign
        id = @event.dig(:action, :campaign_id).to_i
        id.positive? ? Campaign.find_by(client_id: @client.id, id:) : nil
      end

      def event_group
        id = @event.dig(:action, :group_id).to_i
        id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
      end

      def event_stage
        id = @event.dig(:action, :stage_id).to_i
        id.positive? ? Stage.for_client(@client.id).find_by(id:) : nil
      end

      def event_stop_campaigns
        return ['All Campaigns'] if self.event_stop_campaign_ids&.include?(0)

        Campaign.where(client_id: @client.id, id: self.event_stop_campaign_ids).pluck(:name)
      end

      def event_stop_campaign_ids
        @event.dig(:action, :stop_campaign_ids)&.compact_blank
      end

      def event_keywords
        return [] unless @event

        @event[:keywords].join(', ')
      end

      def event_tag
        id = @event.dig(:action, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
      end

      def form_method
        @event.present? ? :patch : :post
      end

      def form_url
        @event.present? && @event.include?(:event_id) ? Rails.application.routes.url_helpers.integrations_cardx_event_path(@event[:event_id]) : Rails.application.routes.url_helpers.integrations_cardx_events_path
      end

      def gateway_accounts
        [
          [@account, @account]
        ]
      end

      def groups_allowed
        @client.groups_count.positive?
      end

      def service_titan_available?(user)
        user.access_controller?('integrations', 'client') && user.client.integrations_allowed.include?('servicetitan') && service_titan_configured?
      end

      def service_titan_configured?
        integration = @client.client_api_integrations.find_by(target: 'servicetitan', name: '')
        return false unless integration
        return false if integration.credentials.blank?

        Integration::Servicetitan::V2::Base.new(integration).valid_credentials?
      end

      def service_titan_payment_types
        Integration::Servicetitan::V2::Base.new(@client.client_api_integrations.find_by(target: 'servicetitan', name: ''))&.payment_types || []
      end

      def stages_allowed
        @client.stages_count.positive?
      end

      # verify that CardX credentials are valid
      # presenter.valid_credentials?
      def valid_credentials?
        @valid_credentials ||= @cx_client.valid_credentials?
      end
    end
  end
end
