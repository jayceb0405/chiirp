# frozen_string_literal: true

# app/lib/dlc_10/campaign_registry/v2/base.rb
module Dlc10
  module CampaignRegistry
    module V2
      class Base
        attr_reader :error, :message, :result, :success

        include CampaignRegistry::V2::Brands
        include CampaignRegistry::V2::Campaigns
        include CampaignRegistry::V2::Enums
        include CampaignRegistry::V2::Resellers
        include CampaignRegistry::V2::Webhooks

        # tcr_client = Dlc10::CampaignRegistry::V2::Base.new
        def initialize
          reset_attributes
          @result = nil
        end

        def errors
          reset_attributes

          tcr_request(
            body:                  nil,
            error_message_prepend: 'Dlc10::CampaignRegistry::V2::Base.errors',
            method:                'get',
            params:                nil,
            default_result:        [],
            url:                   "#{base_api_url}/#{api_version}/error"
          )

          @result
        end

        def success?
          @success
        end

        def tcr_dca_id(phone_vendor)
          case phone_vendor.to_s.downcase
          when 'bandwidth'
            'BANDW'
          when 'sinch'
            'SINCH'
          when 'twilio'
            'TWILO'
          else
            ''
          end
        end

        def tcr_phone_vendor(tcr_dca_id)
          case tcr_dca_id.to_s.upcase
          when 'BANDW'
            'bandwidth'
          when 'SINCH'
            'sinch'
          when 'TWILO'
            'twilio'
          else
            ''
          end
        end

        private

        def api_key
          Rails.application.credentials[:campaign_registry][:api_key]
        end

        def api_version
          'v2'
        end

        def base_api_url
          'https://csp-api.campaignregistry.com'
        end

        def basic_auth
          Base64.urlsafe_encode64("#{api_key}:#{secret}").strip
        end

        def reset_attributes
          @error   = 0
          @message = ''
          @success = false
        end

        def secret
          Rails.application.credentials[:campaign_registry][:secret]
        end

        # tcr_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Dlc10::CampaignRegistry::V2::Base.tcr_request',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def tcr_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Dlc10::CampaignRegistry::V2::Base.tcr_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if url.blank?
            @message = 'The Campaign Registry API URL is required.'
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
                req.headers['Authorization'] = "Basic #{basic_auth}"
                req.headers['Content-Type']  = 'application/json; charset=utf-8'
                req.params                   = params if params.present?
                req.body                     = body.to_json if body.present?
              end
            end

            @message = [@message]

            case @faraday_result&.status
            when 200, 201, 204
              @result  = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
              @result  = if @result.respond_to?(:deep_symbolize_keys)
                           @result.deep_symbolize_keys
                         elsif @result.respond_to?(:map)
                           @result.map { |r| r.respond_to?(:deep_symbolize_keys) ? r.deep_symbolize_keys : r }
                         else
                           @result
                         end
              @success = true
            when 400
              @error   = @faraday_result&.status
              @message = []
              @success = false

              JSON.parse(@faraday_result.body).map(&:symbolize_keys).each do |r|
                @message << case r.dig(:code).to_i
                            when 502
                              ['Brand was not found']
                            when 503
                              ['Duplicate Record was found']
                            when 509
                              ['Campaign request was rejected']
                            when 511
                              ['Mmaximum Campaigns was exceeded']
                            when 512
                              ['Maximum Brand Count was exceeded']
                            when 518
                              ['Campaign: was expired']
                            when 523
                              ['Campaign: detected a loop in campaign sharing chain']
                            when 527
                              ['Brand Pending: Brand is in a \'pending\' state waiting for brand scoring task be to completed.']
                            when 529
                              ['Brand_country: is blacklisted and not allowed to be registered in TCR']
                            when 534
                              ['Sole Proprietor: is not enabled']
                            when 536
                              ['Campaign: may not be shared as a mock campaign']
                            when 590
                              ['TCR: internal system error']
                            when 591, 630
                              ['Temporary System Error: please wait 30 seconds and try again']
                            else
                              ["#{r.dig(:field).to_s.titleize}: #{r.dig(:description)}"]
                            end
              end
            when 401

              if (redos += 1) < 5
                sleep ProcessError::Backoff.full_jitter(redos:)
                redo
              end

              @error   = @faraday_result&.status
              @message = [@faraday_result&.reason_phrase]
              @success = false

              ProcessError::Report.send(
                error_message: "#{error_message_prepend}: #{@faraday_result&.reason_phrase}",
                variables:     {
                  args:                   args.inspect,
                  faraday_result:         @faraday_result&.inspect,
                  faraday_result_methods: @faraday_result&.methods.inspect,
                  redos:,
                  result:                 @result.inspect
                },
                file:          __FILE__,
                line:          __LINE__
              )
            when 404, 405
              @error   = @faraday_result&.status
              @message = [@faraday_result&.reason_phrase]
              @success = false
            else
              @error   = @faraday_result&.status
              @message = ["#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{@faraday_result&.body}"]
              @success = false

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
  end
end
