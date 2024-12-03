# frozen_string_literal: true

# app/lib/integrations/search_light/v1/base.rb
module Integrations
  module SearchLight
    module V1
      class Base
        class SearchLightRequestError < StandardError; end

        attr_accessor :error, :faraday_result, :message, :result, :success

        # initialize SearchLight
        # sl_client = Integrations::SearchLight::V1::Base.new()
        #   (req) client_id:     (Integer)
        #   (req) client_name:   (String)
        #   (req) client_ext_id: (String)
        def initialize(args = {})
          reset_attributes
          @client_id          = args.dig(:client_id).to_i
          @client_name        = args.dig(:client_name).to_s
          @client_ext_id      = args.dig(:client_ext_id).to_s
          @client_integration = args.dig(:client_integration).to_s
        end

        # POST an action to Searchlight
        # sl_client.post_action()
        def post_action(args = {})
          reset_attributes

          if !required_params_defined?
            @message = 'Unknown Searchlight Client.'
            @success = false
            @result  = false
            return false
          elsif args.blank?
            @message = 'Data must be provided to submit to Searchlight.'
            @success = false
            @result  = false
            return false
          end

          body = {
            client_id:          @client_id,
            client_name:        @client_name,
            client_ext_id:      @client_ext_id,
            client_integration: @client_integration
          }.merge(args)

          self.searchlight_request(
            body:,
            error_message_prepend: 'Integrations::SearchLight::Base.post_action',
            method:                'post',
            params:                nil,
            default_result:        false,
            url:                   'https://searchlight.partners/service/event/chiirp'
          )
        end

        def request_key
          reset_attributes

          unless required_params_defined?
            @message = 'Unknown Searchlight Client.'
            @success = false
            @result  = false
            return false
          end

          self.searchlight_request(
            body:                  { client_id: @client_id, client_name: @client_name, tenant_id: @client_ext_id, client_integration: @client_integration },
            error_message_prepend: 'Integrations::SearchLight::Base.request_key',
            method:                'post',
            params:                nil,
            default_result:        {},
            url:                   'https://searchlight.partners/chiirp/register-client'
          )

          if @result.is_a?(Hash) && @result.dig(:key).present?
            @result = @result[:key]
          else
            @success = false
            @result  = ''
          end

          @result
        end

        def success?
          @success
        end

        private

        def auth_token
          Rails.application.credentials[:searchlight][:auth_token]
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'searchlight', client_api_id: @client_id, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end

        # self.searchlight_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::SearchLight::Base.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String,
        # )
        def searchlight_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::SearchLight::Base.searchlight_request'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          record_api_call(error_message_prepend)

          success, error, message = Retryable.with_retries(
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
              req.headers['Authorization'] = self.auth_token
              req.headers['Content-Type']  = 'application/json'
              req.params                   = params if params.present?
              req.body                     = body.to_json if body.present?
            end

            @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
            result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

            case @faraday_result.status
            when 200
              @result  = if result_body.respond_to?(:deep_symbolize_keys)
                           result_body.deep_symbolize_keys
                         elsif result_body.respond_to?(:map)
                           result_body.map(&:deep_symbolize_keys)
                         else
                           result_body
                         end
              # @success = !result_body.nil?
              @success = true
            when 400
              @error   = 400
              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
              @success = false
            when 401
              @error   = 401
              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
              @success = false
            when 404
              @error   = 404
              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
              @success = false
            when 409
              @error   = 409
              @message = "#{@faraday_result.reason_phrase} (#{@faraday_result.status}): #{result_body&.dig('errors', 'id')&.join(', ')}"
              @success = false
            else
              @error   = @faraday_result.status
              @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('errors', 'id')&.join(', ')}"
              @success = false

              error = SearchLightRequestError.new(@message)
              error.set_backtrace(BC.new.clean(caller))

              Appsignal.report_error(error) do |transaction|
                # Only needed if it needs to be different or there's no active transaction from which to inherit it
                Appsignal.set_action(error_message_prepend)

                # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
                Appsignal.add_params(args)

                Appsignal.set_tags(
                  error_level: 'info',
                  error_code:  @error
                )
                Appsignal.add_custom_data(
                  faraday_result:         @faraday_result&.to_hash,
                  faraday_result_methods: @faraday_result&.public_methods.inspect,
                  result:                 @result,
                  result_body:,
                  file:                   __FILE__,
                  line:                   __LINE__
                )
              end
            end
          end

          @success = false unless success
          @error   = error if error.to_i.positive?
          @message = message if message.present?

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end

        def required_params_defined?
          return true if @client_id.positive? && @client_name.present? && @client_ext_id.present? && @client_integration.present?

          @message = 'Client id, name, external id & integration are required.'
          @success = false
          @result  = false
        end
      end
    end
  end
end
