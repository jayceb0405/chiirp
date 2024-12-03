# frozen_string_literal: true

# app/lib/integrations/pc_richard/v1/base.rb
module Integrations
  module PcRichard
    module V1
      class Base
        attr_reader :error, :faraday_result, :message, :result, :token

        # initialize PcRichard
        # pcr_client = Integrations::PcRichard::V1::Base.new(credentials)
        # (req) token: (String)
        def initialize(credentials)
          reset_attributes
          @result      = nil
          @auth_token  = (credentials.dig(:auth_token) || credentials.dig('auth_token')).to_s
        end

        # send install_completed data to PC Richard
        # pcr_client.install_completed()
        # (req) invoice_number: (String)
        # (req) completed_date: (DateTime)
        # (req) notes:          (String)
        # (req) serial_number:  (String)
        def install_completed(args = {})
          reset_attributes
          @result = {}

          if args.dig(:invoice_number).blank?
            @message = 'Invoice number is required.'
            return @result
          elsif args.dig(:completed_date).blank? || !args[:completed_date].respond_to?(:iso8601)
            @message = 'Completed date is required.'
            return @result
          elsif args.dig(:serial_number).blank?
            @message = 'Installed model serial number is required.'
            return @result
          end

          body = {
            invoice_number: args[:invoice_number].to_s,
            completed_date: args[:completed_date].to_date.iso8601,
            notes:          args.dig(:notes).to_s,
            serial_number:  args[:serial_number].to_s
          }
          pcrichard_request(
            body:,
            error_message_prepend: 'Integrations::PcRichard::V1::Base.install_completed',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{server_url}/install_completed/"
          )

          @result
        end

        # send install_scheduled data to PC Richard
        # pcr_client.install_completed()
        # (req) invoice_number: (String)
        # (req) scheduled_date: (DateTime)
        # (req) notes:          (String)
        def install_scheduled(args = {})
          reset_attributes
          @result = {}

          if args.dig(:invoice_number).blank?
            @message = 'Invoice number is required.'
            return @result
          elsif args.dig(:scheduled_date).blank? || !args[:scheduled_date].respond_to?(:iso8601)
            @message = 'Scheduled date is required.'
            return @result
          end

          body = {
            invoice_number: args.dig(:invoice_number).to_s,
            scheduled_date: args.dig(:scheduled_date).to_date.iso8601,
            notes:          args.dig(:notes).to_s
          }
          pcrichard_request(
            body:,
            error_message_prepend: 'Integrations::PcRichard::V1::Base.install_scheduled',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{server_url}/install_scheduled/"
          )

          @result
        end

        # send recommended_info data to PC Richard
        # pcr_client.recommended_models()
        # (req) invoice_number:      (String)
        # (req) installation_charge: (DateTime)
        # (opt) internal_notes:      (String)
        # (opt) receipt_notes:       (String)
        # (req) option_01:       (String)
        # (opt) option_02:       (String)
        # (opt) option_03:       (String)
        # (opt) option_04:       (String)
        # (opt) option_05:       (String)
        # (opt) option_06:       (String)
        def recommended_models(args = {})
          reset_attributes
          @result = {}

          if args.dig(:invoice_number).blank?
            @message = 'Invoice number is required.'
            return @result
          elsif args.dig(:installation_charge).blank?
            @message = 'Installation charge is required.'
            return @result
          end

          body = {
            invoice_number: args.dig(:invoice_number).to_s,
            suggestion_01:  args.dig(:option_01).to_s,
            suggestion_02:  args.dig(:option_02).to_s,
            suggestion_03:  args.dig(:option_03).to_s,
            suggestion_04:  args.dig(:option_04).to_s,
            suggestion_05:  args.dig(:option_05).to_s,
            suggestion_06:  args.dig(:option_06).to_s,
            inst_charges:   args.dig(:installation_charge).to_d,
            receipt_notes:  args.dig(:receipt_notes).to_s,
            internal_notes: args.dig(:internal_notes).to_s
          }
          pcrichard_request(
            body:,
            error_message_prepend: 'Integrations::PcRichard::V1::Base.recommended_models',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{server_url}/recommend_info/"
          )

          @result
        end

        def success?
          @success
        end

        # get supported_models from PC Richard
        # pcr_client.supported_models
        def supported_models
          reset_attributes
          @result = []

          body = {}
          pcrichard_request(
            body:,
            error_message_prepend: 'Integrations::PcRichard::V1::Base.supported_models',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{server_url}/allowed_models/"
          )

          @result = if @result.is_a?(Hash)
                      @result&.dig(:models) || []
                    else
                      []
                    end
        end

        private

        def server_url
          if Rails.env.production?
            'https://apps.pcrichard.com/partner_install'
          else
            'https://apps.pcrichard.com:8082/partner_install'
          end
        end

        # pcrichard_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::PcRichard::V1::Base.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def pcrichard_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::PcRichard::V1::Base.jobber_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if @auth_token.blank?
            @message = 'PcRichard Authorization Token is required.'
            return @result
          elsif url.blank?
            @message = 'PcRichard URL is required.'
            return @result
          end

          record_api_call(error_message_prepend)

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
              req.headers['Authorization']            = "Bearer #{@auth_token}"
              req.headers['Content-Type']             = 'application/json'
              req.headers['Accept']                   = 'application/json'
              req.params                              = params if params.present?
              req.body                                = body.to_json if body.is_a?(Hash)
            end
          end

          case @faraday_result&.status
          when 200
            result   = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result
            @result  = if result.respond_to?(:deep_symbolize_keys)
                         result.deep_symbolize_keys
                       elsif result.respond_to?(:map)
                         result.map(&:deep_symbolize_keys)
                       else
                         result
                       end

            @success = @result.dig(:success).nil? ? true : @result.dig(:success).to_bool
            @message = @result.dig(:error)
          when 401, 404
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = args.dig(:default_result)
            @success = false
          else
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = args.dig(:default_result)
            @success = false

            ProcessError::Report.send(
              error_message: "#{error_message_prepend}: #{@faraday_result&.reason_phrase} (#{@faraday_result&.status}): #{@faraday_result&.body}",
              variables:     {
                args:                   args.inspect,
                faraday_result:         @faraday_result&.inspect,
                faraday_result_methods: @faraday_result&.methods.inspect,
                reason_phrase:          @faraday_result&.reason_phrase.inspect,
                result:                 @result.inspect,
                status:                 @faraday_result&.status.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'pcrichard', client_api_id: @auth_token, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end
      end
    end
  end
end
