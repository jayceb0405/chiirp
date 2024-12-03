# frozen_string_literal: true

# app/lib/phone_numbers/sinch_numbers.rb
module PhoneNumbers
  # process API calls to Sinch to support phone number processing
  class SinchNumbers
    attr_reader :error, :faraday_result, :message, :result

    # initialize SMS::Sinch object
    # si_client = PhoneNumbers::SinchNumbers.new
    def initialize
      reset_attributes
    end

    # PhoneNumbers::Bandwidth.buy()
    #   (req) client_name:  (String)
    #   (req) phone_number: (String)
    def buy(args = {})
      reset_attributes
      @result = response = {
        success:         false,
        phone_number:    '',
        phone_vendor:    'sinch',
        phone_number_id: '',
        vendor_order_id: ''
      }

      return @result unless args.dig(:client_name).present? && args.dig(:phone_number).present?

      begin
        sinch_request(
          body:                  nil,
          error_message_prepend: 'PhoneNumbers::SinchNumbers.buy',
          method:                'post',
          params:                { displayName: args[:client_name], smsConfiguration: { servicePlanId: self.sms_service_plan_id }, voiceConfiguration: { appId: self.voice_app_key } },
          default_result:        @result,
          url:                   "#{self.numbers_url}/availableNumbers/+1#{args[:phone_number]}:rent"
        )
        JsonLog.info 'PhoneNumbers::SinchNumbers.buy', { result: @result }

        response = {
          success:         true,
          phone_number:    @result.dig(:phoneNumber),
          phone_vendor:    'sinch',
          phone_number_id: @result.dig(:projectId),
          vendor_order_id: @result.dig(:projectId)
        }
      rescue StandardError => e
        # Something happened
        ProcessError::Report.send(
          error_message: "PhoneNumbers::SinchNumbers::Buy: #{e.message}",
          variables:     {
            client_name:      args[:client_name].inspect,
            e:                e.inspect,
            e_methods:        e.public_methods.inspect,
            new_phone_number: (defined?(new_phone_number) ? new_phone_number.inspect : 'Undefined'),
            phone_number:     args[:phone_number].inspect,
            response:         response.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      @result = response
    end

    # SMS::Router.destroy(vendor_id: String, phone_number: String)
    # release a phone number back to Sinch
    def destroy(args = {})
      vendor_id     = args.dig(:vendor_id).to_s
      phone_number  = args.dig(:phone_number).to_s
      sinch_client = self.sinch_client
      response = false

      if vendor_id.present?
        begin
          result = sinch_client.incoming_phone_numbers(vendor_id).delete
        rescue Sinch::REST::RestError => e
          result_body = sinch_client&.http_client&.last_response&.body&.symbolize_keys

          if result_body.is_a?(Hash) && result_body.dig(:status).to_i == 404
            # result_body example: {
            #   "code"=>20404,
            #   "message"=>"The requested resource /2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/IncomingPhoneNumbers/SIDPN5dec969d8151678181b703c1335729e2.json was not found",
            #   "more_info"=>"https://www.sinch.com/docs/errors/20404",
            #   "status"=>404
            # }
          else
            ProcessError::Report.send(
              error_message: "PhoneNumbers::SinchNumbers::Destroy: #{e.code}",
              variables:     {
                args:                                        args.inspect,
                e:                                           e.inspect,
                e_body:                                      e.body.inspect,
                e_code:                                      e.code.inspect,
                e_details:                                   e.details.inspect,
                e_error_message:                             e.error_message.inspect,
                e_message:                                   e.message.inspect,
                e_methods:                                   e.public_methods.inspect,
                e_more_info:                                 e.more_info.inspect,
                e_status_code:                               e.status_code.inspect,
                phone_number:                                phone_number.inspect,
                response:                                    response.inspect,
                result:                                      (defined?(result) ? result : nil),
                sinch_client_http_client_last_response_body: sinch_client&.http_client&.last_response&.body.inspect,
                vendor_id:                                   vendor_id.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        rescue StandardError => e
          ProcessError::Report.send(
            error_message: "PhoneNumbers::SinchNumbers::Destroy: #{e.code}",
            variables:     {
              args:                                        args.inspect,
              e:                                           e.inspect,
              e_body:                                      e.body.inspect,
              e_code:                                      e.code.inspect,
              e_details:                                   e.details.inspect,
              e_error_message:                             e.error_message.inspect,
              e_message:                                   e.message.inspect,
              e_methods:                                   e.public_methods.inspect,
              e_more_info:                                 e.more_info.inspect,
              e_status_code:                               e.status_code.inspect,
              phone_number:                                phone_number.inspect,
              response:                                    response.inspect,
              result:                                      (defined?(result) ? result : nil),
              sinch_client_http_client_last_response_body: sinch_client&.http_client&.last_response&.body.inspect,
              vendor_id:                                   vendor_id.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end

        response = true
      end

      if !response && phone_number.length == 10
        leased_phone_numbers = sinch_client.incoming_phone_numbers.list(phone_number: "+1#{phone_number}")

        leased_phone_numbers.each do |number|
          begin
            result = sinch_client.incoming_phone_numbers(number.sid).delete
          rescue StandardError => e
            ProcessError::Report.send(
              error_message: "PhoneNumbers::SinchNumbers::Destroy: #{e.code}",
              variables:     {
                args:                                        args.inspect,
                e:                                           e.inspect,
                e_body:                                      e.body.inspect,
                e_code:                                      e.code.inspect,
                e_details:                                   e.details.inspect,
                e_error_message:                             e.error_message.inspect,
                e_message:                                   e.message.inspect,
                e_methods:                                   e.public_methods.inspect,
                e_more_info:                                 e.more_info.inspect,
                e_status_code:                               e.status_code.inspect,
                leased_phone_numbers:                        leased_phone_numbers.inspect,
                number:                                      number.inspect,
                phone_number:                                phone_number.inspect,
                response:                                    response.inspect,
                result:                                      (defined?(result) ? result : nil),
                sinch_client_http_client_last_response_body: sinch_client&.http_client&.last_response&.body.inspect,
                vendor_id:                                   vendor_id.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end

          response = true
        end
      end

      response
    end

    # search for available phone numbers from Sinch
    # si_client.available_numbers()
    #   (opt) local:     (Boolean)
    #   (opt) toll_free: (Boolean)
    #   (opt) area_code: (String)
    #   (opt) contains:  (String)
    def available_numbers(args = {})
      reset_attributes
      @result = []
      query_params = {}
      query_params[:size] = 50
      # query_params[:capabilities] = '["SMS","VOICE"]'

      if args.dig(:area_code).to_s.length == 3
        query_params[:'numberPattern.pattern']       = "+1#{args[:area_code]}"
        query_params[:'numberPattern.searchPattern'] = 'START'
      elsif args.dig(:contains).to_s.present?
        query_params[:'numberPattern.pattern']       = args[:contains].to_s
        query_params[:'numberPattern.searchPattern'] = 'CONTAINS'
      end

      # regionCode:                  (String) US, CA
      # type:                        (String) MOBILE, LOCAL or TOLL_FREE
      # numberPattern.pattern:       (String) xxxxxx
      # numberPattern.searchPattern: (String) START, CONTAIN, and END
      # capabilities:                (Array)  SMS and/or VOICE
      # size:                        (Integer) maximum number of items to return

      available_phone_numbers = []

      if args.dig(:local).to_bool
        sinch_request(
          body:                  nil,
          error_message_prepend: 'PhoneNumbers::SinchNumbers.available_numbers',
          method:                'get',
          params:                query_params.merge({ regionCode: 'US', type: 'LOCAL' }),
          default_result:        @result,
          url:                   "#{numbers_url}/availableNumbers"
        )
        available_phone_numbers += @result.dig(:availableNumbers) || []

        sinch_request(
          body:                  nil,
          error_message_prepend: 'PhoneNumbers::SinchNumbers.available_numbers',
          method:                'get',
          params:                query_params.merge({ regionCode: 'CA', type: 'LOCAL' }),
          default_result:        @result,
          url:                   "#{numbers_url}/availableNumbers"
        )
        available_phone_numbers += @result.dig(:availableNumbers) || []
      end

      if args.dig(:toll_free).to_bool
        sinch_request(
          body:                  nil,
          error_message_prepend: 'PhoneNumbers::SinchNumbers.available_numbers',
          method:                'get',
          params:                query_params.merge({ regionCode: 'US', type: 'TOLL_FREE' }),
          default_result:        @result,
          url:                   "#{numbers_url}/availableNumbers"
        )
        available_phone_numbers += @result.dig(:availableNumbers) || []

        sinch_request(
          body:                  nil,
          error_message_prepend: 'PhoneNumbers::SinchNumbers.available_numbers',
          method:                'get',
          params:                query_params.merge({ regionCode: 'CA', type: 'TOLL_FREE' }),
          default_result:        @result,
          url:                   "#{numbers_url}/availableNumbers"
        )
        available_phone_numbers += @result.dig(:availableNumbers) || []
      end

      available_phone_numbers = available_phone_numbers.select { |n| n[:phoneNumber].include?(args[:contains].to_s) } if args.dig(:contains).to_s.present?
      JsonLog.info 'PhoneNumbers::SinchNumbers.available_phone_numbers', { available_phone_numbers: }

      @result = available_phone_numbers.map { |pn| { city: 'N/A', state: 'N/A', phone_number: pn.dig(:phoneNumber).sub('+1', '') } }
    end

    # request phone number info from Sinch
    # PhoneNumbers::SinchNumbers.lookup( phone: String, carrier: Boolean, phone_name: Boolean )
    def lookup(args = {})
      phone      = args.dig(:phone).to_s
      carrier    = args.dig(:carrier).to_bool
      phone_name = args.dig(:phone_name).to_bool
      response   = {
        success:             false,
        error_code:          '',
        error_message:       '',
        country_code:        nil,
        national_format:     nil,
        phone_number:        nil,
        caller_name:         nil,
        caller_type:         nil,
        mobile_country_code: nil,
        mobile_network_code: nil,
        name:                nil,
        type:                nil
      }

      return response.merge(error_message: 'Phone number NOT received.') if phone.blank?

      begin
        # lookup phone number
        fetch_types = []
        fetch_types  << 'carrier' if carrier
        fetch_types  << 'caller-name' if phone_name
        sinch_client = self.sinch_client
        result = sinch_client.lookups.phone_numbers(phone).fetch(type: fetch_types)

        response[:success]             = true
        response[:country_code]        = result.country_code
        response[:national_format]     = result.national_format
        response[:phone_number]        = result.phone_number
        response[:caller_name]         = result.caller_name['caller_name'] if phone_name && !result.caller_name.nil?
        response[:caller_type]         = result.caller_name['caller_type'] if phone_name && !result.caller_name.nil?
        response[:mobile_country_code] = result.carrier['mobile_country_code'] if carrier && !result.carrier.nil?
        response[:mobile_network_code] = result.carrier['mobile_network_code'] if carrier && !result.carrier.nil?
        response[:name]                = result.carrier['name'] if carrier && !result.carrier.nil?
        response[:type]                = result.carrier['type'] if carrier && !result.carrier.nil?
      rescue StandardError => e
        # Something happened
        ProcessError::Report.send(
          error_message: "PhoneNumbers::SinchNumbers::Lookup: #{e.message}",
          variables:     {
            args:                                        args.inspect,
            carrier:                                     carrier.inspect,
            e:                                           e.inspect,
            e_methods:                                   e.public_methods.inspect,
            fetch_types:                                 (defined?(fetch_types) ? fetch_types : nil),
            phone:                                       phone.inspect,
            phone_name:                                  phone_name.inspect,
            response:                                    (defined?(response) ? response : nil),
            result:                                      (defined?(result) ? result : nil),
            sinch_client_http_client_last_response_body: defined?(sinch_client.http_client.last_response.body) ? sinch_client.http_client.last_response.body.inspect : 'Undefined',
            file:                                        __FILE__,
            line:                                        __LINE__
          }
        )
      end

      response
    end

    # get array of all phone numbers leased from Sinch
    # PhoneNumbers::SinchNumbers.all_leased_phone_numbers
    def all_leased_phone_numbers
      reset_attributes
      @result = []

      sinch_request(
        body:                  nil,
        error_message_prepend: 'PhoneNumbers::SinchNumbers.all_leased_phone_numbers',
        method:                'get',
        params:                { regionCode: 'US', type: 'LOCAL' },
        default_result:        @result,
        url:                   "#{self.numbers_url}/activeNumbers"
      )
      JsonLog.info 'PhoneNumbers::SinchNumbers.all_leased_phone_numbers', { result: @result }

      @result = @result.dig(:activeNumbers) || []
    end

    # process a callback from Sinch
    # PhoneNumbers::SinchNumbers.callback args
    def callback(args = {})
      {
        success:       true,
        message_sid:   args.dig(:MessageSid).to_s,
        status:        args.dig(:MessageStatus).to_s,
        error_code:    args.dig(:ErrorCode).to_s,
        error_message: ''
      }
    end

    def self.callback_url(_args = {})
      Rails.application.routes.url_helpers.message_msg_callback_url(host: self.url_host, protocol: self.url_protocol)
    end

    def self.capability(role)
      capability = Sinch::JWT::ClientCapability.new Rails.application.credentials[:sinch][:sid], Rails.application.credentials[:sinch][:auth]
      outgoing_scope = Sinch::JWT::ClientCapability::OutgoingClientScope.new Rails.application.credentials[:sinch][:twiml_sid], role
      capability.add_scope outgoing_scope

      incoming_scope = Sinch::JWT::ClientCapability::IncomingClientScope.new role
      capability.add_scope incoming_scope

      capability.to_s
    end

    # get array of data for a specific phone number leased from Sinch
    # PhoneNumbers::SinchNumbers.leased_phone_number( vendor_id: String )
    def leased_phone_number(args = {})
      vendor_id = args.dig(:vendor_id).to_s
      sinch_client = self.sinch_client

      if vendor_id.present?
        # retrieve incoming phone numbers and sid

        begin
          leased_phone_number = sinch_client.incoming_phone_numbers(vendor_id).fetch
        rescue Sinch::REST::RestError => e
          if e.code == 20_404
            ProcessError::Report.send(
              error_code:    e.code.to_s,
              error_message: "PhoneNumbers::SinchNumbers::LeasedPhoneNumber: The requested phone number (id: #{vendor_id}) could not be found.",
              variables:     {
                args:                                        args.inspect,
                e:                                           e.inspect,
                e_code:                                      e.code,
                e_error_message:                             e.error_message.inspect,
                e_methods:                                   e.public_methods.inspect,
                e_status_code:                               e.status_code.inspect,
                leased_phone_number:                         defined?(leased_phone_number) ? leased_phone_number.inspect : 'Undefined',
                sinch_client_http_client_last_response_body: defined?(sinch_client.http_client.last_response.body) ? sinch_client.http_client.last_response.body.inspect : 'Undefined',
                vendor_id:                                   vendor_id.inspect,
                file:                                        __FILE__,
                line:                                        __LINE__
              }
            )
          else
            ProcessError::Report.send(
              error_message: "PhoneNumbers::SinchNumbers::LeasedPhoneNumber: #{e.message}",
              variables:     {
                args:                                        args.inspect,
                e:                                           e.inspect,
                e_code:                                      e.code,
                e_error_message:                             e.error_message.inspect,
                e_methods:                                   e.public_methods.inspect,
                e_status_code:                               e.status_code.inspect,
                leased_phone_number:                         defined?(leased_phone_number) ? leased_phone_number.inspect : 'Undefined',
                sinch_client_http_client_last_response_body: defined?(sinch_client.http_client.last_response.body) ? sinch_client.http_client.last_response.body.inspect : 'Undefined',
                vendor_id:                                   vendor_id.inspect,
                file:                                        __FILE__,
                line:                                        __LINE__
              }
            )
          end

          leased_phone_number = {}
        rescue StandardError => e
          ProcessError::Report.send(
            error_message: "PhoneNumbers::SinchNumbers::LeasedPhoneNumber: #{e.message}",
            variables:     {
              args:                                        args.inspect,
              e:                                           e.inspect,
              e_methods:                                   e.public_methods.inspect,
              leased_phone_number:                         defined?(leased_phone_number) ? leased_phone_number.inspect : 'Undefined',
              sinch_client_http_client_last_response_body: defined?(sinch_client.http_client.last_response.body) ? sinch_client.http_client.last_response.body.inspect : 'Undefined',
              vendor_id:                                   vendor_id.inspect,
              file:                                        __FILE__,
              line:                                        __LINE__
            }
          )

          leased_phone_number = {}
        end
      else
        # return empty hash
        leased_phone_number = {}
      end

      leased_phone_number
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
      @error          = 0
      @faraday_result = nil
      @message        = ''
      @success        = false
    end

    def sinch_client
      Sinch::REST::Client.new(
        Rails.application.credentials[:sinch][:sid],
        Rails.application.credentials[:sinch][:auth]
      )
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
            req.headers['Authorization'] = "Basic #{api_token}"
            req.headers['Content-Type']  = 'application/json'
            req.params                   = params if params.present?
            req.body                     = body.to_json if body.present?
          end
        end

        JsonLog.info 'PhoneNumbers::SinchNumbers.sinch_request', { faraday_result: @faraday_result }

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

      @result
    end

    def sms_service_plan_id
      Rails.application.credentials[:sinch][:sms_service_plan_id]
    end

    def url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end

    def voice_app_key
      Rails.application.credentials[:sinch][:voice_app_key]
    end

    def voice_app_secret
      Rails.application.credentials[:sinch][:voice_app_secret]
    end
  end
end
