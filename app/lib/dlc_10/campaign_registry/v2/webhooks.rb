# frozen_string_literal: true

# app/lib/dlc_10/campaign_registry/v2/webhooks.rb
module Dlc10
  module CampaignRegistry
    module V2
      module Webhooks
        # call CampaignRegistry for webhook event categories available
        # tcr_client.webhook_event_categories
        def webhook_event_categories
          reset_attributes
          @result = {}

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Webhooks.webhook_event_categories',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/eventCategory"
          )

          @result
        end

        # call CampaignRegistry API for webhook event types available
        # tcr_client.webhook_event_types
        def webhook_event_types
          reset_attributes
          @result = {}

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Webhooks.webhook_event_types',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/eventType"
          )

          @result
        end

        # call CampaignRegistry to send a mock webhook for testing
        # tcr_client.webhook_send_mock(event_type)
        # event_types: ['BRAND_ADD', 'BRAND_DELETE', 'CAMPAIGN_ADD', 'CAMPAIGN_EXPIRED', 'CAMPAIGN_SHARE_ACCEPT', 'CAMPAIGN_SHARE_ADD', 'CAMPAIGN_SHARE_DELETE', 'CSP_ACTIVE', 'CSP_APPROVE', 'CSP_SUSPEND', 'EVP_REPORT_FAIL', 'EVP_REPORT_IMPORT', 'EVP_REPORT_SCORE', 'EVP_REPORT_UNSCORE', 'EVP_REPORT_UPDATE', 'MNO_CAMPAIGN_OPERATION_APPROVE'", 'MNO_CAMPAIGN_OPERATION_REJECTED', 'MNO_CAMPAIGN_OPERATION_REVIEW', 'MNO_CAMPAIGN_OPERATION_SUSPENDED', 'MNO_CAMPAIGN_OPERATION_UNSUSPENDED', 'MNO_COMPLAINT']
        def webhook_send_mock(event_type)
          reset_attributes
          @result    = {}
          event_type = event_type.to_s.upcase

          return @result unless self.webhook_event_types.pluck(:eventType).include?(event_type)

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Webhooks.webhook_send_mock',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/subscription/eventType/#{event_type}/mock"
          )

          @result
        end

        # call CampaignRegistry API to subscribe to a webhook category
        # tcr_client.webhook_subscribe(event_category, endpoint)
        # event_categories: ['CSP', 'VETTING', 'INCIDENCE', 'BRAND', 'CAMPAIGN']
        def webhook_subscribe(event_category, endpoint)
          reset_attributes
          @result        = false
          event_category = event_category.to_s.upcase

          return @result if %w[CSP VETTING INCIDENCE BRAND CAMPAIGN].exclude?(event_category) || endpoint.to_s.blank?

          data = {
            eventCategory:   event_category,
            webhookEndpoint: endpoint
          }
          tcr_request(
            body:                  data,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Webhooks.webhook_subscribe',
            method:                'put',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/subscription"
          )

          @result
        end

        # call CampaignRegistry API for webhook subscriptions
        # tcr_client.webhook_subscriptions
        def webhook_subscriptions
          reset_attributes
          @result = {}

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Webhooks.webhook_subscriptions',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/subscription"
          )

          @result
        end

        # call CampaignRegistry API to unsubscribe from a webhook category
        # tcr_client.webhook_unsubscribe(event_category)
        # event_categories: ['CSP', 'VETTING', 'INCIDENCE', 'BRAND', 'CAMPAIGN']
        def webhook_unsubscribe(event_category)
          reset_attributes
          @result        = false
          event_category = event_category.to_s.upcase

          return @result unless %w[CSP VETTING INCIDENCE BRAND CAMPAIGN].include?(event_category)

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Webhooks.webhook_unsubscribe',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_api_url}/#{api_version}/webhook/subscription/#{event_category}"
          )

          @result
        end
      end
    end
  end
end
