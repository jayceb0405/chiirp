# frozen_string_literal: true

# app/lib/integrations/ggl/base.rb
module Integrations
  module Ggl
    # process various API calls to Google
    # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
    class Base
      class GoogleRequestError < StandardError; end

      attr_accessor :error, :faraday_result, :message, :new_token, :refresh_token, :result, :success, :token

      ::Google::Apis.logger = Logger.new(nil)

      include Integrations::Ggl::BusinessMessages::Agents
      include Integrations::Ggl::BusinessMessages::Brands
      include Integrations::Ggl::BusinessMessages::Locations
      include Integrations::Ggl::BusinessMessages::Messages
      include Integrations::Ggl::BusinessMessages::Partners
      include Integrations::Ggl::MyBusiness::Reviews
      include Integrations::Ggl::MyBusinessAccountManagement::Accounts
      include Integrations::Ggl::MyBusinessBusinessInformation::Locations

      # initialize Google
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      def initialize(token = nil, tenant = 'chiirp')
        reset_attributes
        @refresh_token  = nil
        @result         = nil
        @tenant         = tenant.to_s
        @token          = token.to_s

        # Reviews
        @average_rating = {}
        @total_reviews  = {}

        # Business Messages
        @business_messages_token = nil
      end

      # ggl_client.google_service_methods
      def google_service_methods
        JsonLog.info 'Integrations::Ggl::Base.google_service_methods', { methods: google_service.methods }
      end

      # Revoke a Google Oauth2 token
      # ggl_client.revoke_token
      def revoke_token
        return true if @token.blank?

        self.google_request(
          body:                  nil,
          error_message_prepend: 'Integrations::Ggl::Base.RevokeToken',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "https://oauth2.googleapis.com/revoke?token=#{@token}"
        )
      end

      def success?
        @success
      end

      # Validate an existing Google Oauth2 token & refresh if necessary
      # ggl_client.valid_token?
      def valid_token?(refresh_token = @refresh_token)
        reset_attributes
        @result = false
        @refresh_token = refresh_token

        return @result if @token.blank?

        begin
          result = Faraday.post('https://www.googleapis.com/oauth2/v1/tokeninfo') do |req|
            req.params['access_token'] = @token
          end

          if result.status == 200
            scopes = JSON.parse(result.body).deep_symbolize_keys.dig(:scope).split

            if scopes.include?('https://www.googleapis.com/auth/userinfo.email') && scopes.include?('https://www.googleapis.com/auth/userinfo.profile') &&
               scopes.include?('https://www.googleapis.com/auth/calendar') && scopes.include?('https://www.googleapis.com/auth/calendar.events') && scopes.include?('openid') &&
               scopes.include?('https://www.googleapis.com/auth/businesscommunications') && scopes.include?('https://www.googleapis.com/auth/business.manage')

              @result  = true
              @success = @result
            end
          else
            @token   = refresh_access_token
            @result  = @token.present?
            @success = @token.present?
          end
        rescue StandardError => e
          # if e.status_code.to_i == 401
          #   @error   = e.status_code.to_i
          #   @message = 'Expired or invalid Google access token.'
          # else
          # @error_code = e.status_code.to_i
          @error_code = 0
          @message    = "Integrations::Ggl::Base::ValidToken::StandardError: #{e.message}"

          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Ggl::Base.valid_token?')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(
              refresh_token:
            )

            Appsignal.set_tags(
              error_level: 'info',
              error_code:  @error_code
            )
            Appsignal.add_custom_data(
              e_full_message: e.full_message,
              e_methods:      e.public_methods.inspect,
              message:        @message,
              result:         @result,
              result_body:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        end

        @result
      end

      private

      def api_request_limit
        50
      end

      def business_messages_partner_id
        Rails.application.credentials[:google][:business_messages][:partner_id]
      end

      def business_messages_service_account_credentials
        {
          type:                        'service_account',
          project_id:                  'chiirp-calendar-access',
          private_key_id:              Rails.application.credentials[:google][:business_messages][:private_key_id],
          private_key:                 Rails.application.credentials[:google][:business_messages][:private_key].gsub('\\n', "\n"),
          client_email:                Rails.application.credentials[:google][:business_messages][:client_email],
          client_id:                   Rails.application.credentials[:google][:business_messages][:client_id],
          auth_uri:                    'https://accounts.google.com/o/oauth2/auth',
          token_uri:                   'https://oauth2.googleapis.com/token',
          auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
          client_x509_cert_url:        Rails.application.credentials[:google][:business_messages][:client_x509_cert_url]
        }
      end

      def business_messages_token
        @business_messages_token ||= ::Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(self.business_messages_service_account_credentials.to_json), scope: 'https://www.googleapis.com/auth/businessmessages')&.fetch_access_token!&.dig('access_token')
      end

      def business_messages_webhook_url
        Rails.application.routes.url_helpers.integrations_google_messages_endpoint_url(host: self.url_host, protocol: self.url_protocol)
      end

      def google_client
        Signet::OAuth2::Client.new(
          access_token:         @token,
          refresh_token:        @refresh_token,
          client_id:            Rails.application.credentials[:google][@tenant.to_sym][:client_id],
          client_secret:        Rails.application.credentials[:google][@tenant.to_sym][:secret],
          token_credential_uri: 'https://oauth2.googleapis.com/token'
        )
      end

      # Call Google APIs
      # self.google_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::Ggl::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   token:                 String,
      #   url:                   String
      # )
      #  (opt) body:                  (Hash)
      #  (opt) error_message_prepend: (String)
      #  (opt) method:                (String,
      #  (opt) params:                (Hash)
      #  (req) default_result:        (@result)
      #  (opt) token:                 (String)
      #  (req) url:                   (String)
      def google_request(args = {})
        reset_attributes
        body                  = args.dig(:body)
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::Ggl::Base.google_request'
        faraday_method        = (args.dig(:method) || 'get').to_s
        params                = args.dig(:params)
        @result               = args.dig(:default_result)
        token                 = args.dig(:token) || @token
        url                   = args.dig(:url).to_s

        if token.blank?
          @message = 'Client token is required.'
          return @result
        end

        record_api_call(token, error_message_prepend)

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
              req.headers['Content-Type']  = 'application/json; charset=utf-8'
              req.headers['Authorization'] = "Bearer #{token}"
              req.params                   = params if params.present?
              req.body                     = body.to_json if body.present?
            end
          end

          result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : @result

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
          when 401, 403, 404
            @message = "#{@faraday_result&.reason_phrase} (#{@faraday_result&.status}): #{result_body.is_a?(Hash) ? result_body&.dig(:error) : result_body}"
            @success = false
          when 503 # Service Unavailable
            @message = 'Service Unavailable (The service is currently unavailable.): 503'
            @success = false

            if (redos += 1) < 5
              # JsonLog.info error_message_prepend, { redo: redos, faraday_result: @faraday_result }
              Rails.logger.info "#{error_message_prepend}: #{{ redo: redos, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"
              sleep ProcessError::Backoff.full_jitter(redos:)
              redo
            end

            error = GoogleRequestError.new(@message)
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action(error_message_prepend)

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @faraday_result&.status
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
          else
            @message = "#{@faraday_result&.reason_phrase || 'Incomplete Faraday Request'} (#{@faraday_result&.status || 'Unknown Status'}): #{result_body&.dig(:error)}"
            @success = false

            error = GoogleRequestError.new(@message)
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action(error_message_prepend)

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @faraday_result&.status
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

          break
        end

        @success = false unless success
        @error   = error
        @message = message if message.present?

        # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
        Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

        @result
      end

      def google_secret
        ::Google::APIClient::ClientSecrets.new(
          { 'web' =>
                     { 'access_token'  => @token,
                       'refresh_token' => @refresh_token,
                       'client_id'     => Rails.application.credentials[:google][@tenant.to_sym][:client_id],
                       'client_secret' => Rails.application.credentials[:google][@tenant.to_sym][:secret] } }
        )
      end

      def google_service
        service = ::Google::Apis::CalendarV3::CalendarService.new
        service.authorization = google_client

        service
      end

      def my_business_base_url
        'https://mybusiness.googleapis.com'
      end

      def my_business_base_version
        'v4'
      end

      def my_business_business_information_base_url
        'https://mybusinessbusinessinformation.googleapis.com'
      end

      def my_business_business_information_base_version
        'v1'
      end

      def my_business_account_management_base_url
        'https://mybusinessaccountmanagement.googleapis.com'
      end

      def my_business_account_management_base_version
        'v1'
      end

      def record_api_call(token, error_message_prepend)
        Clients::ApiCall.create(target: 'google', client_api_id: token, api_call: error_message_prepend)
      end

      def refresh_access_token(refresh_token = @refresh_token)
        @refresh_token = refresh_token
        response       = ''

        begin
          result   = google_client.fetch_access_token!
          response = result.symbolize_keys[:access_token]
        rescue Signet::AuthorizationError => e
          if e.message.include?('invalid_grant')
            Rails.logger.error "Integrations::Ggl::Base::RefreshAccessToken::Signet::AuthorizationError::InvalidGrant: #{@refresh_token.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          elsif e.message.include?('unauthorized_client')
            Rails.logger.error "Integrations::Ggl::Base::RefreshAccessToken::Signet::AuthorizationError::UnauthorizedClient: #{@refresh_token.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
          else
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Ggl::Base.refresh_access_token')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(
                refresh_token:
              )

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  0
              )
              Appsignal.add_custom_data(
                e_exception:    e.exception,
                e_full_message: e.full_message,
                e_message:      e.message,
                e_methods:      e.public_methods.inspect,
                response:,
                result:,
                file:           __FILE__,
                line:           __LINE__
              )
            end
          end
        rescue StandardError => e
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Ggl::Base.refresh_access_token')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(
              refresh_token:
            )

            Appsignal.set_tags(
              error_level: 'info',
              error_code:  0
            )
            Appsignal.add_custom_data(
              e_exception:    e.exception,
              e_full_message: e.full_message,
              e_message:      e.message,
              e_methods:      e.public_methods.inspect,
              response:,
              result:,
              file:           __FILE__,
              line:           __LINE__
            )
          end
        end

        response
      end

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @success        = false
      end

      def url_host
        I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
      end

      def url_protocol
        I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
      end
    end
  end
end
