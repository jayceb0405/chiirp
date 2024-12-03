# frozen_string_literal: true

# app/lib/dlc_10/sinch.rb
module Dlc10
  # process Campaign Registry (TCR) API calls to Sinch
  class Sinch
    attr_reader :error, :message, :result, :success, :faraday_result

    # initialize Dlc10::Sinch object
    # dlc10_sinch_client = Dlc10::Sinch.new
    def initialize
      reset_attributes
      @result = nil
    end

    # call Sinch API for a specific TCR Campaign
    # dlc10_sinch_client.campaign(tcr_campaign_id)
    def campaign(_tcr_campaign_id)
      reset_attributes
      @success = true
      @result  = {}
    end

    # call Sinch API to apply a phone number to a TCR campaign
    # dlc10_sinch_client.campaign_phone_number(tcr_campaign_id, phone_number)
    def campaign_phone_number(tcr_campaign_id, phone_number)
      reset_attributes
      @result = {}

      return @result unless tcr_campaign_id.to_s.present? && phone_number.to_s.present?

      data = {
        smsConfiguration: {
          campaignId: tcr_campaign_id.to_s
        }
      }

      sinch_request(
        body:                  data,
        error_message_prepend: 'Dlc10::Sinch.campaign_phone_number',
        method:                'patch',
        params:                nil,
        default_result:        @result,
        url:                   "#{self.numbers_url}/activeNumbers/+1#{phone_number}"
      )

      @result
    end
    # example response
    # {
    #   "downstreamCnpId": "string",
    #   "upstreamCnpId": "string",
    #   "sharingStatus": "PENDING",
    #   "explanation": "string",
    #   "sharedDate": "2023-01-23T22:39:10.045Z",
    #   "statusDate": "2023-01-23T22:39:10.045Z"
    # }

    # call TCR API to share a TCR campaign with Sinch
    # dlc10_sinch_client.campaign_share(tcr_campaign_id)
    def campaign_share(tcr_campaign_id)
      reset_attributes

      tcr_client = Dlc10::CampaignRegistry::V2::Base.new
      tcr_client.campaign_share(tcr_campaign_id, 'sinch')

      @success = tcr_client.success?
      @error   = tcr_client.error
      @message = tcr_client.message
      @result = {
        campaign_id: tcr_campaign_id,
        description: tcr_client.result.dig(:explanation).to_s,
        created_at:  tcr_client.result.dig(:sharedDate).to_s,
        status:      tcr_client.result.dig(:sharingStatus).to_s
      }
    end
    # TCR example response
    # {
    #   downstreamCnpId: "string",
    #   upstreamCnpId:   "string",
    #   sharingStatus:   "PENDING",
    #   explanation:     "string",
    #   sharedDate:      "2023-01-20T17:49:39.208Z",
    #   statusDate:      "2023-01-20T17:49:39.208Z"
    # }

    # call Sinch API for a list of Campaigns
    # dlc10_sinch_client.campaigns
    def campaigns
      reset_attributes
      @success = true
      @result  = []
    end

    # call Sinch API for a specific TCR Campaign
    # dlc10_sinch_client.phone_number_options(phone_number)
    def phone_number_options(_phone_number)
      reset_attributes
      @success = true
      @result  = []
    end

    def success?
      @success
    end

    private

    def api_token
      Base64.urlsafe_encode64("#{self.key_id}:#{self.key_secret}")
    end

    def key_id
      Rails.application.credentials[:sinch][:key_id]
    end

    def key_secret
      Rails.application.credentials[:sinch][:key_secret]
    end

    def numbers_url
      "https://numbers.api.sinch.com/v1/projects/#{self.project_id}"
    end

    def project_id
      Rails.application.credentials[:sinch][:project_id]
    end

    def reset_attributes
      @error   = 0
      @message = ''
      @success = false
    end

    # sinch_request(
    #   body:                  Hash,
    #   error_message_prepend: 'SMS::SinchSms::SinchRequest',
    #   method:                String,
    #   params:                Hash,
    #   default_result:        @result,
    #   url:                   String
    # )
    def sinch_request(args = {})
      reset_attributes
      body                  = args.dig(:body)
      error_message_prepend = args.dig(:error_message_prepend) || 'SMS::SinchSms::SinchRequest'
      faraday_method        = (args.dig(:method) || 'get').to_s
      params                = args.dig(:params)
      @result               = args.dig(:default_result)
      url                   = args.dig(:url).to_s

      if url.blank?
        @message = 'Sinch API URL is required.'
        return @result
      end

      loop do
        redos ||= 0

        @success, @error, @message = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          error_message_prepend:,
          current_variables:     {
            parent_body:                  args.dig(:body),
            parent_error_message_prepend: args.dig(:error_message_prepend),
            parent_method:                args.dig(:method),
            parent_params:                args.dig(:params),
            parent_result:                args.dig(:default_result),
            parent_url:                   args.dig(:url),
            parent_file:                  __FILE__,
            parent_line:                  __LINE__
          }
        ) do
          @faraday_result = Faraday.send(faraday_method, url) do |req|
            req.headers['Authorization'] = "Basic #{self.api_token}"
            req.headers['Content-Type']  = 'application/json'
            req.params                   = params if params.present?
            req.body                     = body.to_json if body.present?
          end
        end

        case @faraday_result&.status
        when 200, 201
          result   = JSON.parse(@faraday_result.body)
          @result  = if result.respond_to?(:deep_symbolize_keys)
                       result.deep_symbolize_keys
                     elsif result.respond_to?(:map)
                       result.map(&:deep_symbolize_keys)
                     else
                       result
                     end
          @success = true
        when 401

          if (redos += 1) < 5
            sleep ProcessError::Backoff.full_jitter(redos:)
            redo
          end

          @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"

          ProcessError::Report.send(
            error_message: "#{error_message_prepend}: #{@faraday_result.reason_phrase}",
            variables:     {
              args:                   args.inspect,
              faraday_result:         @faraday_result.inspect,
              faraday_result_methods: @faraday_result&.methods.inspect,
              result:                 @result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        when 404
          @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{@faraday_result.body}"
        else
          @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{@faraday_result&.body}"

          ProcessError::Report.send(
            error_message: "#{error_message_prepend}: #{@message}",
            variables:     {
              args:                   args.inspect,
              faraday_result:         @faraday_result.inspect,
              faraday_result_methods: @faraday_result&.methods.inspect,
              result:                 @result.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end

        break
      end

      # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
      Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

      @result
    end
  end
end
