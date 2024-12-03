# frozen_string_literal: true

# app/lib/phone_numbers/twilio_numbers.rb
module PhoneNumbers
  # process API calls to Twilio to support phone number processing
  module TwilioNumbers
    # get array of all phones numbers leased from Twilio
    # PhoneNumbers::TwilioNumbers.all_leased_phone_numbers
    def self.all_leased_phone_numbers(args = {})
      phone_number         = args.dig(:phone_number).nil? ? true : args.dig(:phone_number).to_bool
      vendor_id            = args.dig(:vendor_id).to_bool
      twilio_client        = self.twilio_client
      leased_phone_numbers = []

      begin
        if phone_number && vendor_id
          # retrieve incoming phone numbers and sid
          leased_phone_numbers = twilio_client.incoming_phone_numbers.list.to_h { |number| [number.phone_number[2, 10], number.sid] }
        elsif phone_number
          # retrieve incoming phone numbers only
          leased_phone_numbers = twilio_client.incoming_phone_numbers.list.collect { |number| number.phone_number[2, 10] }
        elsif vendor_id
          # retrieve incoming phone sid only
          leased_phone_numbers = twilio_client.incoming_phone_numbers.list.collect(&:sid)
        end
      rescue StandardError => e
        ProcessError::Report.send(
          error_message: "PhoneNumbers::TwilioNumbers::AllLeasedPhoneNumbers: #{e.message}",
          variables:     {
            args:                                         args.inspect,
            e:                                            e.inspect,
            e_methods:                                    e.public_methods.inspect,
            leased_phone_numbers:                         defined?(leased_phone_numbers) ? leased_phone_numbers.inspect : 'Undefined',
            phone_number:                                 phone_number.inspect,
            twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
            vendor_id:                                    vendor_id.inspect,
            file:                                         __FILE__,
            line:                                         __LINE__
          }
        )
      end

      leased_phone_numbers
    end
    # {
    #   "end": 0,
    #   "first_page_uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers.json?PageSize=1&Page=0",
    #   "incoming_phone_numbers": [
    #     {
    #       "account_sid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #       "address_requirements": "none",
    #       "address_sid": "ADXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #       "api_version": "2010-04-01",
    #       "beta": null,
    #       "capabilities": {
    #         "mms": true,
    #         "sms": false,
    #         "voice": true
    #       },
    #       "date_created": "Thu, 30 Jul 2015 23:19:04 +0000",
    #       "date_updated": "Thu, 30 Jul 2015 23:19:04 +0000",
    #       "emergency_status": "Active",
    #       "emergency_address_sid": "ADXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #       "friendly_name": "(808) 925-5327",
    #       "identity_sid": "RIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #       "origin": "origin",
    #       "phone_number": "+18089255327",
    #       "sid": "PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #       "sms_application_sid": "",
    #       "sms_fallback_method": "POST",
    #       "sms_fallback_url": "",
    #       "sms_method": "POST",
    #       "sms_url": "",
    #       "status_callback": "",
    #       "status_callback_method": "POST",
    #       "trunk_sid": null,
    #       "uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers/PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.json",
    #       "voice_application_sid": "",
    #       "voice_caller_id_lookup": false,
    #       "voice_fallback_method": "POST",
    #       "voice_fallback_url": null,
    #       "voice_method": "POST",
    #       "voice_url": null
    #     }
    #   ],
    #   "last_page_uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers.json?PageSize=1&Page=2",
    #   "next_page_uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers.json?PageSize=1&Page=1",
    #   "num_pages": 3,
    #   "page": 0,
    #   "page_size": 1,
    #   "previous_page_uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers.json?PageSize=1&Page=0",
    #   "start": 0,
    #   "total": 3,
    #   "uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers.json?PageSize=1"
    # }

    # PhoneNumbers::TwilioNumbers.buy(phone_vendor_sub_account_id: String, client_id: Integer, client_name: String, phone_number: String)
    def self.buy(args = {})
      begin
        new_phone_number = self.twilio_client.incoming_phone_numbers.create(
          friendly_name: args.dig(:client_name).to_s,
          phone_number:  "+1#{args.dig(:phone_number)}",
          sms_url:       "#{I18n.t('tenant.app_protocol')}://#{I18n.t("tenant.#{Rails.env}.app_host")}/message/msgin",
          voice_url:     "#{I18n.t('tenant.app_protocol')}://#{I18n.t("tenant.#{Rails.env}.app_host")}/twvoice/voicein"
        )

        response = {
          success:         true,
          phone_number:    args.dig(:phone_number).to_s,
          phone_vendor:    'twilio',
          phone_number_id: new_phone_number.sid
        }
      rescue StandardError => e
        # Something happened
        ProcessError::Report.send(
          error_message: "PhoneNumbers::TwilioNumbers::TwilioSms::BuyPhoneNumber: #{e.message}",
          variables:     {
            args:             args.inspect,
            e:                e.inspect,
            e_methods:        e.public_methods.inspect,
            new_phone_number: (defined?(new_phone_number) ? new_phone_number.inspect : 'Undefined'),
            response:         response.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )

        response = {
          success:         false,
          phone_number:    '',
          vendor:          '',
          phone_number_id: ''
        }
      end

      response
    end

    # request phone number info from Twilio
    # PhoneNumbers::TwilioNumbers.lookup()
    #   (req) phone:      String
    #   (opt) carrier:    Boolean
    #   (opt) phone_name: Boolean
    def self.lookup(args = {})
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
        fetch_types   = []
        fetch_types  << 'carrier' if carrier
        fetch_types  << 'caller-name' if phone_name
        twilio_client = self.twilio_client
        result = twilio_client.lookups.phone_numbers(phone).fetch(type: fetch_types)

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
          error_message: "PhoneNumbers::TwilioNumbers::Lookup: #{e.message}",
          variables:     {
            args:                                         args.inspect,
            carrier:                                      carrier.inspect,
            e:                                            e.inspect,
            e_methods:                                    e.public_methods.inspect,
            fetch_types:                                  (defined?(fetch_types) ? fetch_types : nil),
            phone:                                        phone.inspect,
            phone_name:                                   phone_name.inspect,
            response:                                     (defined?(response) ? response : nil),
            result:                                       (defined?(result) ? result : nil),
            twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
            file:                                         __FILE__,
            line:                                         __LINE__
          }
        )
      end

      response
    end
    # costs:
    #   format lookup: free
    #   caller_name lookup: $0.01
    #   carrier lookup: $0.005
    # {
    #   "caller_name": {
    #     "caller_name": "Delicious Cheese Cake",
    #     "caller_type": "CONSUMER",
    #     "error_code": null
    #   },
    #   "carrier": {
    #     "error_code": null,
    #     "mobile_country_code": "310",
    #     "mobile_network_code": "456",
    #     "name": "verizon",
    #     "type": "mobile" / "landline" / "voip" / "null"
    #   },
    #   "country_code": "US",
    #   "national_format": "(510) 867-5310",
    #   "phone_number": "+15108675310",
    #   "add_ons": {
    #     "status": "successful",
    #     "message": null,
    #     "code": null,
    #     "results": {}
    #   },
    #   "url": "https://lookups.twilio.com/v1/PhoneNumbers/phone_number"
    # }

    # process a callback from Twilio
    # PhoneNumbers::TwilioNumbers.callback args
    def self.callback(args = {})
      {
        success:       true,
        message_sid:   args.dig(:MessageSid).to_s,
        status:        args.dig(:MessageStatus).to_s,
        error_code:    args.dig(:ErrorCode).to_s,
        error_message: ''
      }
    end
    # Twilio client response:
    # {
    #   "SmsSid": "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "SmsStatus": "accepted / queued / sending / sent / receiving / received / delivered / undelivered / failed",
    #   "MessageStatus": "accepted / queued / sending / sent / receiving / received / delivered / undelivered / failed",
    #   "To": "+18023455136",
    #   "MessageSid": "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "AccountSid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "From": "+18025001302",
    #   "ApiVersion": "2010-04-01"
    # }

    def self.callback_url(_args = {})
      Rails.application.routes.url_helpers.message_msg_callback_url(host: self.url_host, protocol: self.url_protocol)
    end

    def self.capability(role)
      capability = Twilio::JWT::ClientCapability.new Rails.application.credentials[:twilio][:sid], Rails.application.credentials[:twilio][:auth]
      outgoing_scope = Twilio::JWT::ClientCapability::OutgoingClientScope.new Rails.application.credentials[:twilio][:twiml_sid], role
      capability.add_scope outgoing_scope

      incoming_scope = Twilio::JWT::ClientCapability::IncomingClientScope.new role
      capability.add_scope incoming_scope

      capability.to_s
    end

    # SMS::Router.destroy(vendor_id: String, phone_number: String)
    # release a phone number back to Twilio
    def self.destroy(args = {})
      vendor_id     = args.dig(:vendor_id).to_s
      phone_number  = args.dig(:phone_number).to_s
      twilio_client = self.twilio_client
      response      = false

      if vendor_id.present?
        begin
          result = twilio_client.incoming_phone_numbers(vendor_id).delete
        rescue Twilio::REST::RestError => e
          result_body = twilio_client&.http_client&.last_response&.body&.symbolize_keys

          if result_body.is_a?(Hash) && result_body.dig(:status).to_i == 404
            # result_body example: {
            #   "code"=>20404,
            #   "message"=>"The requested resource /2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/IncomingPhoneNumbers/SIDPN5dec969d8151678181b703c1335729e2.json was not found",
            #   "more_info"=>"https://www.twilio.com/docs/errors/20404",
            #   "status"=>404
            # }
          else
            ProcessError::Report.send(
              error_message: "PhoneNumbers::TwilioNumbers::Destroy: #{e.code}",
              variables:     {
                args:                                         args.inspect,
                e:                                            e.inspect,
                e_body:                                       e.body.inspect,
                e_code:                                       e.code.inspect,
                e_details:                                    e.details.inspect,
                e_error_message:                              e.error_message.inspect,
                e_message:                                    e.message.inspect,
                e_methods:                                    e.public_methods.inspect,
                e_more_info:                                  e.more_info.inspect,
                e_status_code:                                e.status_code.inspect,
                phone_number:                                 phone_number.inspect,
                response:                                     response.inspect,
                result:                                       (defined?(result) ? result : nil),
                twilio_client_http_client_last_response_body: twilio_client&.http_client&.last_response&.body.inspect,
                vendor_id:                                    vendor_id.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        rescue StandardError => e
          ProcessError::Report.send(
            error_message: "PhoneNumbers::TwilioNumbers::Destroy: #{e.code}",
            variables:     {
              args:                                         args.inspect,
              e:                                            e.inspect,
              e_body:                                       e.body.inspect,
              e_code:                                       e.code.inspect,
              e_details:                                    e.details.inspect,
              e_error_message:                              e.error_message.inspect,
              e_message:                                    e.message.inspect,
              e_methods:                                    e.public_methods.inspect,
              e_more_info:                                  e.more_info.inspect,
              e_status_code:                                e.status_code.inspect,
              phone_number:                                 phone_number.inspect,
              response:                                     response.inspect,
              result:                                       (defined?(result) ? result : nil),
              twilio_client_http_client_last_response_body: twilio_client&.http_client&.last_response&.body.inspect,
              vendor_id:                                    vendor_id.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end

        response = true
      end

      if !response && phone_number.length == 10
        leased_phone_numbers = twilio_client.incoming_phone_numbers.list(phone_number: "+1#{phone_number}")

        leased_phone_numbers.each do |number|
          begin
            result = twilio_client.incoming_phone_numbers(number.sid).delete
          rescue StandardError => e
            ProcessError::Report.send(
              error_message: "PhoneNumbers::TwilioNumbers::Destroy: #{e.code}",
              variables:     {
                args:                                         args.inspect,
                e:                                            e.inspect,
                e_body:                                       e.body.inspect,
                e_code:                                       e.code.inspect,
                e_details:                                    e.details.inspect,
                e_error_message:                              e.error_message.inspect,
                e_message:                                    e.message.inspect,
                e_methods:                                    e.public_methods.inspect,
                e_more_info:                                  e.more_info.inspect,
                e_status_code:                                e.status_code.inspect,
                leased_phone_numbers:                         leased_phone_numbers.inspect,
                number:                                       number.inspect,
                phone_number:                                 phone_number.inspect,
                response:                                     response.inspect,
                result:                                       (defined?(result) ? result : nil),
                twilio_client_http_client_last_response_body: twilio_client&.http_client&.last_response&.body.inspect,
                vendor_id:                                    vendor_id.inspect
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

    # find phone numbers from Twilio
    # PhoneNumbers::TwilioNumbers.find(contains: String, area_code: String, local: Boolean, toll_free: Boolean)
    def self.find(args = {})
      query_params = {}
      query_params[:contains]      = args[:contains] if args.dig(:contains).to_s.present?
      query_params[:area_code]     = args[:area_code].to_s if args.dig(:area_code).to_s.length == 3
      query_params[:limit]         = 50
      query_params[:voice_enabled] = true
      query_params[:sms_enabled]   = true
      query_params[:mms_enabled]   = true

      twilio_client                = self.twilio_client
      available_phone_numbers      = []

      begin
        if args.dig(:local).to_bool
          available_phone_numbers += twilio_client.api.available_phone_numbers('US').local.list(**query_params)
          available_phone_numbers += twilio_client.api.available_phone_numbers('CA').local.list(**query_params)
        end

        if args.dig(:toll_free).to_bool
          available_phone_numbers += twilio_client.api.available_phone_numbers('US').toll_free.list(**query_params)
          available_phone_numbers += twilio_client.api.available_phone_numbers('CA').toll_free.list(**query_params)
        end
      rescue Twilio::REST::RestError => e
        ProcessError::Report.send(
          error_message: "PhoneNumbers::TwilioNumbers::Find: #{e.message}",
          variables:     {
            args:                                         args.inspect,
            available_phone_numbers:                      available_phone_numbers.inspect,
            e:                                            e.inspect,
            e_code:                                       e.code,
            e_error_message:                              e.error_message.inspect,
            e_methods:                                    e.public_methods.inspect,
            e_status_code:                                e.status_code.inspect,
            query_params:                                 query_params.inspect,
            twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined'
          },
          file:          __FILE__,
          line:          __LINE__
        )
      rescue StandardError => e
        ProcessError::Report.send(
          error_message: "PhoneNumbers::TwilioNumbers::Find: #{e.message}",
          variables:     {
            args:                                         args.inspect,
            available_phone_numbers:                      available_phone_numbers.inspect,
            e:                                            e.inspect,
            e_exception:                                  e.exception.inspect,
            e_cause:                                      e.cause.inspect,
            e_full_message:                               defined?(e.full_message) ? e.full_message.inspect : 'Undefined',
            e_methods:                                    e.public_methods.inspect,
            query_params:                                 query_params.inspect,
            twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined'
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end

      available_phone_numbers.map { |x| { city: x.locality, state: x.region, phone_number: x.phone_number.sub('+1', '') } }.sort_by { |x| x[:phone_number] }
    end

    # get array of data for a specific phone number leased from Twilio
    # PhoneNumbers::TwilioNumbers.leased_phone_number( vendor_id: String )
    def self.leased_phone_number(args = {})
      vendor_id     = args.dig(:vendor_id).to_s
      twilio_client = self.twilio_client

      if vendor_id.present?
        # retrieve incoming phone numbers and sid

        begin
          leased_phone_number = twilio_client.incoming_phone_numbers(vendor_id).fetch
        rescue Twilio::REST::RestError => e
          if e.code == 20_404
            ProcessError::Report.send(
              error_code:    e.code.to_s,
              error_message: "PhoneNumbers::TwilioNumbers::LeasedPhoneNumber: The requested phone number (id: #{vendor_id}) could not be found.",
              variables:     {
                args:                                         args.inspect,
                e:                                            e.inspect,
                e_code:                                       e.code,
                e_error_message:                              e.error_message.inspect,
                e_methods:                                    e.public_methods.inspect,
                e_status_code:                                e.status_code.inspect,
                leased_phone_number:                          defined?(leased_phone_number) ? leased_phone_number.inspect : 'Undefined',
                twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
                vendor_id:                                    vendor_id.inspect,
                file:                                         __FILE__,
                line:                                         __LINE__
              }
            )
          else
            ProcessError::Report.send(
              error_message: "PhoneNumbers::TwilioNumbers::LeasedPhoneNumber: #{e.message}",
              variables:     {
                args:                                         args.inspect,
                e:                                            e.inspect,
                e_code:                                       e.code,
                e_error_message:                              e.error_message.inspect,
                e_methods:                                    e.public_methods.inspect,
                e_status_code:                                e.status_code.inspect,
                leased_phone_number:                          defined?(leased_phone_number) ? leased_phone_number.inspect : 'Undefined',
                twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
                vendor_id:                                    vendor_id.inspect,
                file:                                         __FILE__,
                line:                                         __LINE__
              }
            )
          end

          leased_phone_number = {}
        rescue StandardError => e
          ProcessError::Report.send(
            error_message: "PhoneNumbers::TwilioNumbers::LeasedPhoneNumber: #{e.message}",
            variables:     {
              args:                                         args.inspect,
              e:                                            e.inspect,
              e_methods:                                    e.public_methods.inspect,
              leased_phone_number:                          defined?(leased_phone_number) ? leased_phone_number.inspect : 'Undefined',
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              vendor_id:                                    vendor_id.inspect,
              file:                                         __FILE__,
              line:                                         __LINE__
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
    # {
    #   "account_sid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "address_requirements": "none",
    #   "address_sid": "ADXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "api_version": "2010-04-01",
    #   "beta": false,
    #   "capabilities": {
    #     "mms": true,
    #     "sms": false,
    #     "voice": true
    #   },
    #   "date_created": "Thu, 30 Jul 2015 23:19:04 +0000",
    #   "date_updated": "Thu, 30 Jul 2015 23:19:04 +0000",
    #   "emergency_status": "Active",
    #   "emergency_address_sid": "ADXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "friendly_name": "(808) 925-5327",
    #   "identity_sid": "RIXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "origin": "origin",
    #   "phone_number": "+18089255327",
    #   "sid": "PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "sms_application_sid": null,
    #   "sms_fallback_method": "POST",
    #   "sms_fallback_url": "",
    #   "sms_method": "POST",
    #   "sms_url": "",
    #   "status_callback": "",
    #   "status_callback_method": "POST",
    #   "trunk_sid": null,
    #   "uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/IncomingPhoneNumbers/PNXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.json",
    #   "voice_application_sid": null,
    #   "voice_caller_id_lookup": false,
    #   "voice_fallback_method": "POST",
    #   "voice_fallback_url": null,
    #   "voice_method": "POST",
    #   "voice_url": null
    # }

    def self.twilio_client
      Twilio::REST::Client.new(
        Rails.application.credentials[:twilio][:sid],
        Rails.application.credentials[:twilio][:auth]
      )
    end

    def self.url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def self.url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end
  end
end
