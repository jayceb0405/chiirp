# frozen_string_literal: true

# Integration::Callrail::V3::Base
# app/models/integration/callrail/v3/base.rb
module Integration
  module Callrail
    module V3
      class Base < ApplicationRecord
        # do not use this list to validate data coming in from CallRail
        # this is only to be used to aid with select fields for our clients/users
        CALL_TYPES = [
          %w[Abandoned abandoned],
          %w[Answered answered],
          ['In Progress', 'in_progress'],
          %w[Missed missed],
          %w[Voicemail voicemail],
          ['Voicemail Transcription', 'voicemail_transcription']
        ].freeze
        LEAD_STATUSES = [
          ['Good Lead', 'good_lead'],
          ['Not A Lead', 'not_a_lead'],
          ['Previously Marked Good Lead', 'previously_marked_good_lead'],
          %w[Unknown null]
        ].freeze
        WEBHOOK_TYPES = [
          ['Inbound Post Call', 'inbound_post_call'],
          ['Outbound Post Call', 'outbound_post_call'],
          ['Form Submission', 'form_submission']
        ].freeze

        # validate the access_token & refresh if necessary
        # Integration::Callrail::V3::Base.valid_credentials?(ClientApiIntegration)
        # (req) client_api_integration: (ClientApiIntegration)
        def self.valid_credentials?(client_api_integration)
          self.credentials_exist?(client_api_integration) && Integrations::CallRail::V3::Base.new(client_api_integration.credentials).valid_credentials?
        end

        def self.credentials_exist?(client_api_integration)
          client_api_integration.credentials&.dig('api_key').present?
        end

        # Integration::Callrail::V3::Base.split_account_company_id(account_company_id)
        def self.split_account_company_id(account_company_id)
          [
            account_company_id&.split('::')&.first, # account_id
            account_company_id&.split('::')&.last # company_id
          ]
        end
      end
    end
  end
end
