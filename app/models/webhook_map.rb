# frozen_string_literal: true

# app/models/webhook_map.rb
class WebhookMap < ApplicationRecord
  belongs_to :webhook

  serialize :response, coder: YAML, type: Hash
end
