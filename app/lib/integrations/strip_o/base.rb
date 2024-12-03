# frozen_string_literal: true

# app/lib/integrations/strip_o/base.rb
module Integrations
  module StripO
    class Base
      attr_reader :error, :faraday_result, :message, :result, :token

      # initialize StripO
      # stripo_client = Integrations::StripO::Base.new()
      def initialize
        reset_attributes
      end

      # call Stripo API to get compiled HTML for template
      # stripo_client.compiled_html()
      # Integrations::StripO::Base.new.compiled_html()
      #   (req) html:    (String)
      #   (req) css:     (String)
      #   (opt) minimize (Boolean)
      def compiled_html(html:, css:, minimize: false)
        reset_attributes
        @result = ''

        return @result unless html.to_s.present? & css.to_s.present?

        self.stripo_request(
          body:                  { html: html.to_s, css: css.to_s, minimize: },
          error_message_prepend: 'Integrations::StripO::Base.compiled_html',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   'https://plugins.stripo.email/api/v1/cleaner/v1/compress'
        )

        if @result.is_a?(Hash)
          @result = @result.dig(:html).to_s
        else
          @result  = ''
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end

      def success?
        @success
      end

      private

      def auth_token
        self.stripo_request(
          body:                  { pluginId: Rails.application.credentials[:stripo][I18n.t('tenant.id').to_sym][:plugin_id], secretKey: Rails.application.credentials[:stripo][I18n.t('tenant.id').to_sym][:secret_key] },
          error_message_prepend: 'Integrations::StripO::Base.xxx',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   'https://plugins.stripo.email/api/v1/auth'
        )

        if @result.is_a?(Hash)
          @result = "Bearer #{@result.dig(:token)}"
        else
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
          @result  = ''
        end

        @result
      end

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @success        = false
      end

      # self.stripo_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::StripO::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String
      # )
      def stripo_request(args = {})
        reset_attributes
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::StripO::Base.stripo_request'
        @result               = args.dig(:default_result)

        success, error, message = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError],
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
          @faraday_result = Faraday.send((args.dig(:method) || 'get').to_s, args.dig(:url).to_s) do |req|
            req.headers['ES-PLUGIN-AUTH'] = self.auth_token unless args.dig(:url).to_s.include?('api/v1/auth')
            req.headers['Content-Type']   = 'application/json'
            req.headers['Accept']         = 'application/json'
            req.params                    = args[:params] if args.dig(:params).present?
            req.body                      = args[:body].to_json if args.dig(:body).present?
          end

          @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
          result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

          case @faraday_result&.status
          when 200
            @result  = if result_body.respond_to?(:deep_symbolize_keys)
                         result_body.deep_symbolize_keys
                       elsif result_body.respond_to?(:map)
                         result_body.map(&:deep_symbolize_keys)
                       else
                         result_body
                       end
            @success = !result_body.nil?
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
          when 429
            @error   = 429
            @message = result_body.dig('title')
            @success = false
          else
            @error   = @faraday_result&.status
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig('errors', 'id')&.join(', ')}"
            @success = false

            ProcessError::Report.send(
              error_message: "#{error_message_prepend}: #{@message}",
              variables:     {
                args:                   args.inspect,
                faraday_result:         @faraday_result.inspect,
                faraday_result_methods: @faraday_result&.methods.inspect,
                result:                 @result.inspect,
                result_body:            result_body.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        end

        @success = false unless success
        @error   = error if error.to_i.positive?
        @message = message if message.present?

        # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
        Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

        @result
      end
    end
  end
end
