# frozen_string_literal: true

# app/lib/integrations/service_titan/base.rb
module Integrations
  module ServiceTitan
    class Base
      class ServiceTitanRequestError < StandardError; end

      attr_accessor :error, :faraday_result, :message, :page_size, :result, :success

      include ServiceTitan::Accounting
      include ServiceTitan::Crm
      include ServiceTitan::CrmBookings
      include ServiceTitan::CrmCustomers
      include ServiceTitan::CrmLeads
      include ServiceTitan::CrmLocations
      include ServiceTitan::CrmNotes
      include ServiceTitan::Dispatch
      include ServiceTitan::Estimates
      include ServiceTitan::Jbce
      include ServiceTitan::JpmJobs
      include ServiceTitan::JpmJobTypes
      include ServiceTitan::Marketing
      include ServiceTitan::Memberships
      include ServiceTitan::Payments
      include ServiceTitan::Pricebook
      include ServiceTitan::Reports
      include ServiceTitan::Settings
      include ServiceTitan::SettingsEmployees
      include ServiceTitan::SettingsTechnicians
      include ServiceTitan::Telecom

      # initialize ServiceTitan
      # st_client = Integrations::ServiceTitan::Base.new()
      #   (req) credentials: (Hash)
      def initialize(credentials = {})
        reset_attributes
        @credentials     = credentials.symbolize_keys
        @page_size       = 500
        @max_page_size   = 5000
        @result          = { access_token: '', expires: 0 }
        @save_attributes = {}
      end

      def access_token_valid?
        self.access_token.present? && Time.at(self.access_token_expires - 300).utc.future?
      end

      def credentials_valid?
        @credentials.is_a?(Hash)
      end

      def credentials_client_id_valid?
        @credentials.dig(:client_id).present?
      end

      def credentials_client_secret_valid?
        @credentials.dig(:client_secret).present?
      end

      ##### NOT USED #####
      # method used to determine current API calls count in REDIS
      # def api_call_lookup(sec)
      #   RedisCloud.redis.get("servicetitan_api_call:#{sec}").to_i
      # end

      ##### NOT USED #####
      # method used as counter to track API calls using REDIS
      # def api_call_register!(call_count = 1)
      #   sec = Time.current.sec
      #   raise(StandardError, 'Maximum API call count exceeded!') if RedisCloud.redis.incrby("servicetitan_api_call:#{sec}", call_count) > 60

      #   RedisCloud.redis.expire("servicetitan_api_call:#{sec}", 59)

      #   true
      # end

      # extract ContactApiIntegration data from ServiceTitan CustomerModel
      # st_client.parse_contact_api_integration()
      #   (req) event_params: (Hash / ServiceTitan event params)
      def parse_contact_api_integration(event_params)
        reset_attributes
        @result = { account_balance: 0.0, completion_date: nil }

        self.push_attributes('parse_contact_api_integration')
        customer_data = self.parse_customer(st_customer_model: event_params.dig(:customer))
        self.pull_attributes('parse_contact_api_integration')

        if customer_data.dig(:customer_id).to_i.positive?
          @success                  = true
          @result[:account_balance] = customer_data.dig(:account_balance).to_d
          @result[:completion_date] = Chronic.parse(event_params[:completedOn]).utc.iso8601 if event_params.dig(:completedOn).to_s.present?
        end

        @result
      end

      def success?
        @success
      end

      # retreive a new access token from ServiceTitan
      # st_client.update_access_token
      def update_access_token
        reset_attributes
        @result = {}

        if !credentials_valid?
          @message = 'Client credentials are required.'
          return @result
        elsif !credentials_client_id_valid?
          @message = 'Client ID is required.'
          return @result
        elsif !credentials_client_secret_valid?
          @message = 'Client Secret is required.'
          return @result
        end

        success, error, message = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError],
          error_message_prepend: 'Integrations::ServiceTitan::Base.update_access_token',
          current_variables:     {
            parent_file: __FILE__,
            parent_line: __LINE__
          }
        ) do
          @faraday_result = Faraday.post("#{base_auth_url}/connect/token") do |req|
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
            req.headers['User-Agent']   = 'curl/business-communications'
            req.body                    = api_credentials
          end
        end

        result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body).deep_symbolize_keys : nil

        if @faraday_result&.status == 200 && @faraday_result&.reason_phrase.to_s.casecmp?('ok')
          @result = {
            access_token: result_body&.dig(:access_token).to_s,
            expires:      Time.current.to_i + result_body&.dig(:expires_in).to_i
          }
          @success = true
        else
          @error   = @faraday_result&.status
          @message = "#{@faraday_result&.reason_phrase}, #{result_body&.dig(:error)}"
          @success = false
        end

        @error    = error if error.present?
        @message  = message if message.present?
        @success  = false unless success

        @result
      end

      def valid_token?; end

      private

      def api_credentials
        {
          grant_type:    'client_credentials',
          client_id:     @credentials.dig(:client_id).to_s,
          client_secret: @credentials.dig(:client_secret).to_s
        }
      end

      def access_token
        @credentials.dig(:access_token)
      end

      def access_token_expires
        @credentials.dig(:access_token_expires).to_i
      end

      def app_key
        Rails.application.credentials[:servicetitan][:"app_key_#{@credentials.dig(:app_id)}"]
      end

      def api_method_accounting
        'accounting'
      end

      def api_method_crm
        'crm'
      end

      def api_method_dispatch
        'dispatch'
      end

      def api_method_estimates
        'sales'
      end

      def api_method_jbce
        'jbce'
      end

      def api_method_jpm
        'jpm'
      end

      def api_method_marketing
        'marketing'
      end

      def api_method_memberships
        'memberships'
      end

      def api_method_pricebook
        'pricebook'
      end

      def api_method_reporting
        'reporting'
      end

      def api_method_settings
        'settings'
      end

      def api_method_telecom
        'telecom'
      end

      def api_version
        'v2'
      end

      def base_url
        # rubocop:disable Style/IdenticalConditionalBranches, Lint/DuplicateBranch
        if Rails.env.production?
          'https://api.servicetitan.io'
        else
          'https://api.servicetitan.io'
          # 'https://api-integration.servicetitan.io'
        end
        # rubocop:enable Style/IdenticalConditionalBranches, Lint/DuplicateBranch
      end

      def base_auth_url
        # rubocop:disable Style/IdenticalConditionalBranches, Lint/DuplicateBranch
        if Rails.env.production?
          'https://auth.servicetitan.io'
        else
          'https://auth.servicetitan.io'
          # 'https://auth-integration.servicetitan.io'
        end
        # rubocop:enable Style/IdenticalConditionalBranches, Lint/DuplicateBranch
      end

      def normalize_phone_label(label)
        label = 'MobilePhone' if label.downcase.include?('mobile')
        label = 'Fax' if label.downcase.include?('fax')
        label = 'Phone' unless %w[MobilePhone Fax].include?(label)

        label
      end

      def pull_attributes(location)
        @error          = @save_attributes[location][:error]
        @faraday_result = @save_attributes[location][:faraday_result]
        @message        = @save_attributes[location][:message]
        @result         = @save_attributes[location][:result]
        @success        = @save_attributes[location][:success]
      end

      def push_attributes(location)
        @save_attributes[location] = {
          error:          @error,
          faraday_result: @faraday_result,
          message:        @message,
          result:         @result,
          success:        @success
        }
      end

      def record_api_call(error_message_prepend)
        Clients::ApiCall.create(target: 'servicetitan', client_api_id: @credentials.dig(:client_id), api_call: error_message_prepend)
      end

      def reset_attributes
        @error          = 0
        @faraday_result = nil
        @message        = ''
        @success        = false
      end

      # self.servicetitan_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::ServiceTitan::Base.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String
      # )
      def servicetitan_request(args = {})
        reset_attributes
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::ServiceTitan::Base.servicetitan_request'
        @result               = args.dig(:default_result)

        if self.access_token.blank?
          @message = 'ServiceTitan access token is required.'
          return @result
        elsif self.access_token.present? && !access_token_valid?
          @message = 'ServiceTitan access token must be valid.'
          return @result
        elsif app_key.blank?
          @message = 'ServiceTitan app key is required.'
          return @result
        end

        record_api_call(error_message_prepend)

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
            req.headers['Authorization'] = self.access_token
            req.headers['ST-App-Key']    = app_key
            req.headers['Content-Type']  = 'application/json'
            req.params                   = args[:params] if args.dig(:params).present?
            req.body                     = args[:body].to_json if args.dig(:body).present?
          end

          @faraday_result&.env&.dig('request_headers')&.delete('Authorization')
          result_body = JSON.is_json?(@faraday_result&.body) ? JSON.parse(@faraday_result.body) : nil

          case @faraday_result&.status
          when 200
            @result  = if result_body.respond_to?(:deep_symbolize_keys)
                         result_body.deep_symbolize_keys&.normalize_non_ascii
                       elsif result_body.respond_to?(:map)
                         result_body.map(&:deep_symbolize_keys)&.normalize_non_ascii
                       else
                         result_body&.normalize_non_ascii
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

            error = ServiceTitanRequestError.new(@message)
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

      def tenant_id
        @credentials.dig(:tenant_id)
      end
    end
  end
end
