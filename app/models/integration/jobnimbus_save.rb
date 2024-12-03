# frozen_string_literal: true

# app/models/integration/jobnimbus.rb
module Integration
  # ServiceMonster data processing
  class JobnimbusSave < ApplicationRecord
    # Integration::Jobnimbus.webhook_by_id(Hash, String)
    def self.webhook_by_id(webhooks, webhook_event_id)
      webhook = webhooks.find { |_k, v| v.find { |e| e.dig('event_id').to_s == webhook_event_id } } || []
      webhook.present? ? [webhook].to_h.deep_symbolize_keys : {}
    end

    # Integration::Jobnimbus.webhook_event_by_id(Hash, String)
    def self.webhook_event_by_id(webhooks, webhook_event_id)
      webhooks.find { |_k, v| v.find { |x| x.dig('event_id').to_s == webhook_event_id } }&.last&.find { |x| x.dig('event_id').to_s == webhook_event_id }&.deep_symbolize_keys
    end

    # Integration::Jobnimbus.webhook_object_by_id(Hash, String)
    def self.webhook_object_by_id(webhooks, webhook_event_id)
      webhooks.find { |_k, v| v.find { |x| x.dig('event_id').to_s == webhook_event_id } }&.first
    end
  end
end
