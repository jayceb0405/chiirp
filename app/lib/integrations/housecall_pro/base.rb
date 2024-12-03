# frozen_string_literal: true

# app/lib/integrations/housecall_pro/base.rb
module Integrations
  module HousecallPro
    class Base
      class HousecallProRequestError < StandardError; end

      attr_accessor :error, :faraday_result, :message, :page_size, :refresh_token, :result, :success

      include HousecallPro::Customers
      include HousecallPro::Estimates
      include HousecallPro::Jobs
      include HousecallPro::Parsers
      include HousecallPro::Technicians

      # initialize HousecallPro
      # Integrations::HousecallPro::Base.new()
      # hcp_client = Integrations::HousecallPro::Base.new()
      #   (req) credentials: (Hash)
      def initialize(credentials = {})
        reset_attributes
        @result       = nil
        @credentials  = credentials&.symbolize_keys || {}
      end

      # retreive a new access token from Housecall Pro
      # hcp_client.access_token
      def access_token
        reset_attributes
        @result = {
          access_token:            @credentials.dig(:access_token).to_s,
          access_token_expires_at: @credentials.dig(:access_token_expires_at).to_i,
          refresh_token:           @credentials.dig(:refresh_token).to_s
        }

        if @credentials.dig(:refresh_token).blank?
          @message = 'Refresh token is required.'
          return @credentials
        end

        @result = self.request_access_token(refresh_token: @credentials.dig(:refresh_token).to_s)
      end

      def access_token_valid?
        @credentials.dig(:access_token).present? && Time.at(@credentials.dig(:access_token_expires_at).to_i - 300).utc.future?
      end

      # get Housecall Pro company info
      # hcp_client.company
      def company
        reset_attributes
        @result = {}

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Base.company',
          method:                'get',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/company"
        )

        @result[:phone_number] = @result.dig(:phone_number).to_s.clean_phone

        @result
      end

      # stop webhooks from Housecall Pro
      # hcp_client.deprovision_webhooks
      def deprovision_webhooks
        reset_attributes
        @result = false

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Base.deprovision_webhooks',
          method:                'delete',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/webhooks/subscription"
        )

        @result = @result == '' && @success
      end

      # start webhooks from Housecall Pro
      # hcp_client.provision_webhooks
      def provision_webhooks
        reset_attributes
        @result = false

        self.housecallpro_request(
          body:                  nil,
          error_message_prepend: 'Integrations::HousecallPro::Base.provision_webhooks',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/webhooks/subscription"
        )

        @result = @result == '' && @success
      end

      # send token request to Housecall Pro
      # hcp_client.request_access_token()
      # hcp_client.request_access_token()
      #   (req) auth_code:     (String) only accessed to get an initial access & refresh tokens
      #       ~ or ~
      #   (req) refresh_token: (String) used to refresh tokens
      def request_access_token(args = {})
        reset_attributes
        auth_code      = args.dig(:auth_code).to_s
        refresh_token  = args.dig(:refresh_token).to_s
        default_result = { access_token: '', access_token_expires_at: 0, refresh_token: args.dig(:refresh_token).to_s }

        if auth_code.empty? && refresh_token.empty?
          @message = 'Housecall Pro authorization / refresh token code is required.'
          return default_result
        end

        body = {
          client_id:     credentials_client_id.to_s,
          client_secret: credentials_secret.to_s,
          redirect_uri:  auth_code_url.to_s
        }

        if auth_code.present?
          body[:grant_type] = 'authorization_code'
          body[:code]       = auth_code
        else
          body[:grant_type]    = 'refresh_token'
          body[:refresh_token] = refresh_token.to_s
        end

        self.housecallpro_request(
          body:,
          error_message_prepend: 'Integrations::HousecallPro::Base.request_access_token',
          method:                'post',
          params:                nil,
          default_result:,
          url:                   "#{base_url}/oauth/token"
        )

        if @faraday_result&.status == 200 && @result.is_a?(Hash)
          @result = {
            access_token:            @result.dig(:access_token).to_s,
            access_token_expires_at: (Time.at(@result.dig(:created_at).to_i).utc + @result.dig(:expires_in).to_i.seconds).to_i,
            refresh_token:           @result.dig(:refresh_token)
          }
          @success = true
        else
          @result  = default_result
          @success = false
        end

        @result
      end

      # URL used by Housecall Pro to send auth to
      # hcp_client.request_authentication
      def request_authentication_url
        "#{base_url}/oauth/authorize?response_type=code&client_id=#{credentials_client_id}&redirect_uri=#{auth_code_url}"
      end

      # revoke Housecall Pro access tokens
      # hcp_client.revoke_access_token
      def revoke_access_token
        reset_attributes
        @result = false

        body = {
          client_id:     credentials_client_id.to_s,
          client_secret: credentials_secret.to_s,
          token:         @credentials.dig(:access_token).to_s
        }

        self.housecallpro_request(
          body:,
          error_message_prepend: 'Integrations::HousecallPro::Base.revoke_access_token',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/oauth/revoke"
        )

        if @faraday_result&.status == 200 && @result.is_a?(Hash)
          @success = true
          @result  = true
        else
          @result  = false
          @success = false
        end

        @success = false unless success
        @error   = error
        @message = message if message.present?

        @result
      end

      def success?
        @success
      end

      private

      def app_host
        I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
      end

      def app_protocol
        I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
      end

      def auth_code_url
        Rails.application.routes.url_helpers.integrations_housecall_auth_code_url(host: self.app_host, protocol: self.app_protocol)
      end

      def base_url
        'https://api.housecallpro.com'
      end

      def credentials_client_id
        Rails.application.credentials[:housecall][:client_id]
      end

      def credentials_secret
        Rails.application.credentials[:housecall][:secret]
      end

      def credentials_valid?
        @credentials.is_a?(Hash)
      end

      # self.housecallpro_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::HousecallPro::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String
      # )
      def housecallpro_request(args = {})
        reset_attributes
        body                  = args.dig(:body)
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::HousecallPro::Base.housecallpro_request'
        faraday_method        = (args.dig(:method) || 'get').to_s
        params                = args.dig(:params)
        @result               = args.dig(:default_result)
        url                   = args.dig(:url).to_s

        record_api_call(error_message_prepend)

        Retryable.with_retries(
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
            req.headers['Authorization'] = "Bearer #{@credentials[:access_token]}" if @credentials.dig(:access_token).present?
            req.headers['Content-Type']  = 'application/json'
            req.params                   = params if params.present?
            req.body                     = body.to_json if body.present?
          end

          result_body = if JSON.is_json?(@faraday_result&.body)
                          JSON.parse(@faraday_result.body)
                        elsif @faraday_result&.body == ''
                          ''
                        end

          case @faraday_result.status
          when 200, 201
            @result  = if result_body.respond_to?(:deep_symbolize_keys)
                         result_body.deep_symbolize_keys
                       elsif result_body.respond_to?(:map)
                         result_body.map(&:deep_symbolize_keys)
                       else
                         result_body
                       end
            @success = !result_body.nil?
          when 401
            @message = 'Unauthorized Housecall Pro API access.'
            @success = false
          when 403
            # {error: "unauthorized_client", error_description: "You are not authorized to revoke this token"}
            @message = JSON.parse(@faraday_result.body).symbolize_keys.dig(:error_description).to_s
            @success = false
          when 404
            @message = 'Housecall Pro data was not found.'
            @success = false
          else
            @error   = @faraday_result&.status
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig(:error)}"

            error = HousecallProRequestError.new(@message)
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

        # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
        Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

        @result
      end

      def record_api_call(error_message_prepend)
        Clients::ApiCall.create(target: 'housecallpro', client_api_id: @credentials[:access_token], api_call: error_message_prepend)
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
