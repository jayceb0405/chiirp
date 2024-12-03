# frozen_string_literal: true

# app/models/integration/responsibid.rb
module Integration
  # ServiceMonster data processing
  class Responsibid < ApplicationRecord
    # Integration::Responsibid.update_custom_events(client_api_integration: ClientApiIntegration, webhook_event: String)
    def self.update_custom_events(**args)
      client_api_integration = args.dig(:client_api_integration)
      webhook_event          = args.dig(:webhook_event).to_s

      return unless client_api_integration.is_a?(ClientApiIntegration) && webhook_event.present?
      return if (client_api_integration.custom_events || []).include?(webhook_event)
      return if %w[open pending scheduled closed visit declined].include?(webhook_event) || webhook_event == 'job in jobber'

      client_api_integration.update(custom_events: ((client_api_integration.custom_events || []) << webhook_event).uniq.sort)
    end

    # Integration::Responsibid.update_estimate(Contact, Hash)
    def self.update_estimate(contact, parsed_webhook)
      return nil unless parsed_webhook.dig(:contact, :ext_id).present? && (contact_estimate = contact.estimates.find_or_initialize_by(ext_source: 'responsibid', ext_id: parsed_webhook.dig(:contact, :ext_id)))

      contact_estimate.update(
        status:                   parsed_webhook.dig(:event_status).to_s,
        address_01:               parsed_webhook.dig(:contact, :address_01).to_s,
        address_02:               parsed_webhook.dig(:contact, :address_02).to_s,
        city:                     parsed_webhook.dig(:contact, :city).to_s,
        state:                    parsed_webhook.dig(:contact, :state).to_s,
        postal_code:              parsed_webhook.dig(:contact, :postal_code).to_s,
        country:                  parsed_webhook.dig(:contact, :country).to_s,
        scheduled_start_at:       parsed_webhook.dig(:scheduled_start_at).present? ? Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:scheduled_start_at).strftime('%m/%d/%Y %I:%M:%S%P')) }.utc : nil,
        scheduled_end_at:         parsed_webhook.dig(:scheduled_end_at).present? ? Time.use_zone(contact.client.time_zone) { Chronic.parse(parsed_webhook.dig(:scheduled_end_at).strftime('%m/%d/%Y %I:%M:%S%P')) }.utc : nil,
        scheduled_arrival_window: parsed_webhook.dig(:scheduled_arrival_window).to_i,
        notes:                    parsed_webhook.dig(:notes).to_s,
        proposal_url:             parsed_webhook.dig(:proposal_url).to_s
      )

      contact_estimate.id
    end

    # Integration::Responsibid.webhook_by_id(Hash, String)
    def self.webhook_by_id(webhooks, webhook_event_id)
      webhook = webhooks.find { |_k, v| v.find { |e| e.dig('event_id').to_s == webhook_event_id } } || {}
      webhook.present? ? [webhook].to_h.deep_symbolize_keys : {}
    end

    # Integration::Responsibid.webhook_event_by_id(Hash, String)
    def self.webhook_event_by_id(webhooks, webhook_event_id)
      webhooks.find { |_k, v| v.find { |x| x.dig('event_id').to_s == webhook_event_id } }&.last&.find { |x| x.dig('event_id').to_s == webhook_event_id }&.deep_symbolize_keys
    end

    # Integration::Responsibid.webhook_object_by_id(Hash, String)
    def self.webhook_object_by_id(webhooks, webhook_event_id)
      webhooks.find { |_k, v| v.find { |x| x.dig('event_id').to_s == webhook_event_id } }&.first
    end

    # Integration::Responsibid.webhooks
    # open, pending, scheduled, closed, visit, declined, job in jobber
    def self.webhooks(custom_events = [])
      custom_events ||= []
      [
        { name: 'Open Bid', event: 'open', description: 'Open bid' },
        { name: 'Pending Bid', event: 'pending', description: 'Pending bid' },
        { name: 'Scheduled Bid', event: 'scheduled', description: 'Scheduled bid' },
        { name: 'Closed Bid', event: 'closed', description: 'Closed bid' },
        { name: 'Visit for Bid', event: 'visit', description: 'Visit for bid' },
        { name: 'Declined Bid', event: 'declined', description: 'Declined bid' },
        { name: 'Job in Jobber', event: 'job in jobber', description: 'Job in Jobber' }
      ] + custom_events&.map { |e| { name: e.titleize, event: e, description: e.capitalize } }
    end
  end
end
