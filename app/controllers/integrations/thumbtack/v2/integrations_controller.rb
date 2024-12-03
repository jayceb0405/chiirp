# frozen_string_literal: true

# app/controllers/integrations/thumbtack/v2/integrations_controller.rb
module Integrations
  module Thumbtack
    module V2
      class IntegrationsController < Thumbtack::IntegrationsController
        before_action :authenticate_webhook
        skip_before_action :authenticate_user!, only: %i[endpoint_lead endpoint_lead_update endpoint_message endpoint_review]
        skip_before_action :authorize_user!, only: %i[endpoint_lead endpoint_lead_update endpoint_message endpoint_review]
        skip_before_action :verify_authenticity_token, only: %i[endpoint_lead endpoint_lead_update endpoint_message endpoint_review]
        skip_before_action :client, only: %i[endpoint_lead endpoint_lead_update endpoint_message endpoint_review]
        skip_before_action :client_api_integration, only: %i[endpoint_lead endpoint_lead_update endpoint_message endpoint_review]

        # (POST) Thumbtack webhook endpoint for leads
        # /integrations/thumbtack/v2/endpoint/lead
        # integrations_thumbtack_v2_endpoint_lead_path
        # integrations_thumbtack_v2_endpoint_lead_url
        def endpoint_lead
          sanitized_params = params_endpoint_lead
          client_api_integration_count = 0

          ClientApiIntegration.joins(:client).where(target: 'thumbtack', name: '').where('client_api_integrations.data @> ?', { credentials: { account: { business_pk: sanitized_params.dig(:business, :businessID) } } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
            next if client_api_integration.data.dig('credentials', 'version').blank?

            client_api_integration_count += 1
            Integrations::Thumbtack::V2::ProcessEventJob.perform_later(
              client_api_integration_id: client_api_integration.id,
              webhook_type:              'lead',
              params:                    sanitized_params
            )
          end

          if client_api_integration_count.positive?
            head :ok
          else
            head :not_found
          end
        end

        # (PUT) Thumbtack webhook endpoint for lead updates
        # /integrations/thumbtack/v2/endpoint/lead_update
        # integrations_thumbtack_v2_endpoint_lead_update_path
        # integrations_thumbtack_v2_endpoint_lead_update_url
        def endpoint_lead_update
          head :accepted
          # sanitized_params = params_endpoint_lead_update
          # client_api_integration_count = 0

          # ClientApiIntegration.joins(:client).where(target: 'thumbtack', name: '').where('client_api_integrations.data @> ?', { account: { id: sanitized_params.dig(:webHookEvent, :accountId) } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
          #   next if client_api_integration.data.dig('credentials', 'version').blank?

          #   client_api_integration_count += 1
          #   data = {
          #     client_api_integration_id: client_api_integration.id,
          #     account_id:                sanitized_params.dig(:webHookEvent, :accountId),
          #     item_id:                   sanitized_params.dig(:webHookEvent, :itemId),
          #     process_events:            true,
          #     raw_params:                params.except(:integration),
          #     topic:                     sanitized_params.dig(:webHookEvent, :topic)
          #   }
          #   "Integration::Thumbtack::V#{client_api_integration.data.dig('credentials', 'version')}::Event".constantize.new(data).delay(
          #     run_at:              Time.current,
          #     priority:            DelayedJob.job_priority('thumbtack_process_event'),
          #     queue:               DelayedJob.job_queue('thumbtack_process_event'),
          #     user_id:             0,
          #     contact_id:          0,
          #     triggeraction_id:    0,
          #     contact_campaign_id: 0,
          #     group_process:       0,
          #     process:             'thumbtack_process_event',
          #     data:
          #   ).process
          # end

          # if client_api_integration_count.positive?
          #   render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
          # else
          #   render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
          # end
        end

        # (PUT) Thumbtack webhook endpoint for messages
        # /integrations/thumbtack/v2/endpoint/message
        # integrations_thumbtack_v2_endpoint_message_path
        # integrations_thumbtack_v2_endpoint_message_url
        def endpoint_message
          head :ok
          # sanitized_params = params_endpoint_message
          # client_api_integration_count = 0

          # ClientApiIntegration.joins(:client).where(target: 'thumbtack', name: '').where('client_api_integrations.data @> ?', { account: { id: sanitized_params.dig(:webHookEvent, :accountId) } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
          #   next if client_api_integration.data.dig('credentials', 'version').blank?

          #   client_api_integration_count += 1
          #   data = {
          #     client_api_integration_id: client_api_integration.id,
          #     account_id:                sanitized_params.dig(:webHookEvent, :accountId),
          #     item_id:                   sanitized_params.dig(:webHookEvent, :itemId),
          #     process_events:            true,
          #     raw_params:                params.except(:integration),
          #     topic:                     sanitized_params.dig(:webHookEvent, :topic)
          #   }
          #   "Integration::Thumbtack::V#{client_api_integration.data.dig('credentials', 'version')}::Event".constantize.new(data).delay(
          #     run_at:              Time.current,
          #     priority:            DelayedJob.job_priority('thumbtack_process_event'),
          #     queue:               DelayedJob.job_queue('thumbtack_process_event'),
          #     user_id:             0,
          #     contact_id:          0,
          #     triggeraction_id:    0,
          #     contact_campaign_id: 0,
          #     group_process:       0,
          #     process:             'thumbtack_process_event',
          #     data:
          #   ).process
          # end

          # if client_api_integration_count.positive?
          #   render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
          # else
          #   render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
          # end
        end

        # (PUT) Thumbtack webhook endpoint for reviews
        # /integrations/thumbtack/v2/endpoint/review
        # integrations_thumbtack_v2_endpoint_review_path
        # integrations_thumbtack_v2_endpoint_review_url
        def endpoint_review
          head :ok
          # sanitized_params = params_endpoint_review
          # client_api_integration_count = 0

          # ClientApiIntegration.joins(:client).where(target: 'thumbtack', name: '').where('client_api_integrations.data @> ?', { account: { id: sanitized_params.dig(:webHookEvent, :accountId) } }.to_json).where('clients.data @> ?', { active: true }.to_json).find_each do |client_api_integration|
          #   next if client_api_integration.data.dig('credentials', 'version').blank?

          #   client_api_integration_count += 1
          #   data = {
          #     client_api_integration_id: client_api_integration.id,
          #     account_id:                sanitized_params.dig(:webHookEvent, :accountId),
          #     item_id:                   sanitized_params.dig(:webHookEvent, :itemId),
          #     process_events:            true,
          #     raw_params:                params.except(:integration),
          #     topic:                     sanitized_params.dig(:webHookEvent, :topic)
          #   }
          #   "Integration::Thumbtack::V#{client_api_integration.data.dig('credentials', 'version')}::Event".constantize.new(data).delay(
          #     run_at:              Time.current,
          #     priority:            DelayedJob.job_priority('thumbtack_process_event'),
          #     queue:               DelayedJob.job_queue('thumbtack_process_event'),
          #     user_id:             0,
          #     contact_id:          0,
          #     triggeraction_id:    0,
          #     contact_campaign_id: 0,
          #     group_process:       0,
          #     process:             'thumbtack_process_event',
          #     data:
          #   ).process
          # end

          # if client_api_integration_count.positive?
          #   render plain: 'ok', content_type: 'text/plain', layout: false, status: :ok
          # else
          #   render plain: 'not found', content_type: 'text/plain', layout: false, status: :not_found
          # end
        end

        # (GET) show Thumbtack overview
        # /integrations/thumbtack/v2
        # integrations_thumbtack_v2_path
        # integrations_thumbtack_v2_url
        def show; end

        private

        def params_endpoint_lead
          params.permit(:leadID, :createTimestamp, :leadType, :leadPrice, :chargeState, request: [:requestID, :category, :categoryID, :title, :description, :schedule, :travelPreferences, { details: %i[question answer], attachments: %i[fileName fileSize mimeType url description], location: %i[address1 address2 city state zipCode] }], customer: %i[customerID name phone], business: %i[businessID name])
        end
        # example Thumbtack lead endpoint
        # {
        #   leadID:          '299614694480093245',
        #   createTimestamp: '1498760294',
        #   request:         {
        #     requestID:         '2999842694480093245',
        #     category:          'Interior Painting',
        #     categoryID:        '122681972262289742',
        #     title:             'Interior Painting',
        #     description:       'There is a stain on the door that needs to be touched up.',
        #     schedule:          "Date: Tue, May 05 2020\nTime: 6:00 PM\nLength: 3.5 hours",
        #     location:          {
        #       address1: '101 Alma Street',
        #       address2: '',
        #       city:     'Palo Alto',
        #       state:    'CA',
        #       zipCode:  '94301'
        #     },
        #     travelPreferences: 'Professional must travel to my address.',
        #     details:           [
        #       {
        #         question: 'Type of property',
        #         answer:   'Home'
        #       },
        #       {
        #         question: 'Number of rooms',
        #         answer:   '4 rooms'
        #       }
        #     ],
        #     attachments:       [
        #       {
        #         fileName:    'door.jpg',
        #         fileSize:    1139,
        #         mimeType:    'image/jpeg',
        #         url:         'https://www.thumbtack.com/attachment/b180b7d3bf981dd2896732f979f44fbf45fc4224/door.jpg',
        #         description: 'my stain'
        #       }
        #     ]
        #   },
        #   customer:        {
        #     customerID: '331138063184986319',
        #     name:       'John Davis',
        #     phone:      '1234567890'
        #   },
        #   business:        {
        #     businessID: '286845156044809661',
        #     name:       "Tim's Painting Business"
        #   },
        #   leadType:        'INSTANT_BOOK',
        #   leadPrice:       nil,
        #   chargeState:     nil
        # }

        def params_endpoint_lead_update
          params.permit(:leadID, :leadPrice, :chargeState)
        end
        # example Thumbtack lead update endpoint
        # {
        #   leadID:      '465324000282984455',
        #   leadPrice:   '$26.00',
        #   chargeState: 'Charged'
        # }

        def params_endpoint_message
          params.permit(:leadID, :customerID, :businessID, message: [:messageID, :createTimestamp, :text, { attachments: %i[fileName fileSize mimeType url description] }])
        end
        # example Thumbtack message endpoint
        # {
        #   leadID:     '299614694480093245',
        #   customerID: '331138063184986319',
        #   businessID: '286845156044809661',
        #   message:    {
        #     messageID:       '8699842694484326245',
        #     createTimestamp: '1498760294',
        #     text:            'Do you offer fridge cleaning or is that extra?',
        #     attachments:     [
        #       {
        #         fileName:    'fridge.jpg',
        #         fileSize:    3940,
        #         mimeType:    'image/jpeg',
        #         url:         'https://www.thumbtack.com/attachment/b180b7d3bf981dd2896732f979f44fbf45fc4224/fridge.jpg',
        #         description: 'refrigerator'
        #       }
        #     ]
        #   }
        # }

        def params_endpoint_review
          params.permit(:reviewEventType, review: [:businessID, :categoryID, :createTime, :leadID, :modifyTime, :rating, :reviewID, :reviewerNickname, :text, :verified, { photos: %i[fileName fileSize mimeType url description] }])
        end
        # example Thumbtack review endpoint
        # {
        #   review:          {
        #     businessID:       '286845156044809661',
        #     categoryID:       '299614694480093245',
        #     createTime:       '1517986598726',
        #     leadID:           '299614694480093245',
        #     modifyTime:       '1517986598726',
        #     photos:           [
        #       {
        #         description: 'test review photo',
        #         fileName:    'test_review_photo.jpg',
        #         fileSize:    20,
        #         mimeType:    'image/jpeg',
        #         url:         'test.url.com/attachment/b180b7d3bf981dd2896732f979f44fbf45fc4224/test_review_photo.jpg'
        #       }
        #     ],
        #     rating:           '4',
        #     reviewID:         '318840849076158553',
        #     reviewerNickname: 'Nick Name',
        #     text:             'best service ever',
        #     verified:         true
        #   },
        #   reviewEventType: 'REVIEW_ADDED'
        # }

        def authenticate_webhook
          user = authenticate_with_http_basic { |username, password| username == Rails.application.credentials.dig(:thumbtack, :webhook_username) && password == Rails.application.credentials.dig(:thumbtack, :webhook_password) }

          request_http_basic_authentication unless user
        end
      end
    end
  end
end
