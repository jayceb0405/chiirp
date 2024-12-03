# frozen_string_literal: true

# app/lib/integrations/card_x/base.rb
# https://developer.cardx.com/
module Integrations
  module CardX
    # process various API calls to CardX
    class Base
      attr_reader :account, :error, :faraday_result, :message, :result

      include CardX::Transactions

      # initialize CardX
      # cx_client = Integrations::CardX::Base.new(account)
      # (req) account: (String)
      def initialize(account)
        reset_attributes
        @result = nil
        @account = account
      end

      # Hosted Lightbox Integration is what we use
      # urls look like: https://cardx.com/pay-<DBA name>?amount=100.0&billingZip=92544&name=Tester%20Joe
      def lightbox_url(args = {})
        uri = Addressable::URI.new(scheme: 'https', host: 'cardx.com', path: lightbox_path)
        params = {}
        params[:name] = args.dig(:name) if args.dig(:name).present?
        params[:amount] = args.dig(:amount) if args.dig(:amount).present?
        params[:billingEmail] = args.dig(:email) if args.dig(:email).present?
        params[:billingZip] = args.dig(:zip) if args.dig(:zip).present?
        params[:redirect] = args.dig(:redirect) if args.dig(:redirect).present?
        params[:invoiceIdentifier] = args.dig(:job_id) if args.dig(:job_id).present?
        params[:accountIdentifier] = args.dig(:contact_id) if args.dig(:contact_id).present?
        uri.query_values = params if params.any?
        uri.to_s
      end

      def success?
        @success
      end

      def valid_credentials?
        @account.present?
      end

      private

      def lightbox_path
        Rails.env.production? ? "/pay-#{account}" : "/testaccount-#{account}"
      end

      def api_url
        Rails.env.production? ? nil : 'https://test.api.paywithcardx.com'
      end

      # cardx_request(
      #   body:                  Hash,
      #   error_message_prepend: 'Integrations::CardX.xxx',
      #   method:                String,
      #   params:                Hash,
      #   default_result:        @result,
      #   url:                   String
      # )
      def cardx_request(args = {})
        reset_attributes
        body                  = args.dig(:body)
        error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::CardX.CardXRequest'
        faraday_method        = (args.dig(:method) || 'get').to_s
        params                = args.dig(:params)
        @result               = args.dig(:default_result)
        url                   = args.dig(:url).to_s
        url                   = "#{api_url}#{url}"

        if url.blank?
          @message = 'CardX API URL is required.'
          return @result
        end

        # loop do
        #   redos ||= 0

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
            req.headers['X-Gateway-Account']        = @account
            req.headers['X-Gateway-Api-Key-Name']   = @key_name
            req.headers['X-Gateway-Api-Key']        = @key
            req.headers['Content-Type']             = 'application/json'
            req.headers['Accept']                   = 'application/json'
            req.params                              = params if params.present?
            req.body                                = body.to_json if body.present?
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

          if @result.is_a?(Hash)

            case @result.dig(:Code).to_i
            when 404, 405, 411, 412, 500
              @message = @result.dig(:Message).to_s
              @result  = args.dig(:default_result)
              @success = false
            end
          end
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
        Clients::ApiCall.create(target: 'cardx', client_api_id: @account, api_call: error_message_prepend)
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
