# frozen_string_literal: true

# app/lib/SMS/twilio_sms.rb
module SMS
  # process API calls to Twilio to support text message processing
  module TwilioSms
    # SMS segments
    #   GSM 03.38 character set
    #   160 characters
    #   7 bits/character
    #   (140 bytes * 8 bits) / 7 bits = 160 characters

    #   UCS2 character set
    #   70 characters
    #   16 bits/character
    #   (140 bytes * 8 bits) / 16 bits = 70 characters

    #   multi-segment texts
    #   lose 6 bytes/segment for headers
    #   GSM = 153 characters
    #   UCS2 = 67 characters

    # process a callback from Twilio
    # SMS::TwilioSms.callback args
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

    def self.notify(ios_registration, body)
      self.twilio_client.notify
          .services(Rails.application.credentials[:twilio][:notify_apn_sid])
          .notifications
          .create(body:, identity: ios_registration)
    end

    # receive params from Twilio incoming message webhook
    # message = SMS::TwilioSms.receive(**params)
    def self.receive(args = {})
      to_phone    = args.dig('To').to_s
      from_phone  = args.dig('From').to_s
      content     = args.dig('Body').to_s
      response    = { success: false, message: [], error_code: '', error_message: '' }

      if to_phone.empty?
        response[:error_message] = 'Expected \'To Phone\' missing.'
      elsif from_phone.empty?
        response[:error_message] = 'Expected \'From Phone\' missing.'
      else
        response[:success] = true
        response[:message] = {
          from_phone:,
          to_phone:,
          content:,
          media_array:   [],
          segment_count: [args.dig('NumSegments').to_i, 1].max,
          status:        (args.dig('SmsStatus') || 'received').to_s,
          message_sid:   args.dig('MessageSid').to_s,
          account_sid:   args.dig('AccountSid').to_s,
          to_city:       args.dig('ToCity').to_s,
          to_state:      args.dig('ToState').to_s,
          to_zip:        args.dig('ToZip').to_s,
          to_country:    args.dig('ToCountry').to_s,
          from_city:     args.dig('FromCity').to_s,
          from_state:    args.dig('FromState').to_s,
          from_zip:      args.dig('FromZip').to_s,
          from_country:  args.dig('FromCountry').to_s
        }

        if args.dig('NumMedia').to_i.positive?

          (0..(args.dig('NumMedia').to_i - 1)).each do |m|
            response[:message][:media_array] << args.dig("MediaUrl#{m}") if args.dig("MediaUrl#{m}")
          end
        end
      end

      response
    end
    # {
    #   "ToCountry"=>"US",
    #   "ToState"=>"FL",
    #   "SmsMessageSid"=>"MMa87e504535c5c7587c2aae14a149fa93",
    #   "ToCity"=>"ORANGE CITY",
    #   "FromZip"=>"05701",
    #   "SmsSid"=>"MMa87e504535c5c7587c2aae14a149fa93",
    #   "FromState"=>"VT",
    #   "SmsStatus"=>"received",
    #   "FromCity"=>"RUTLAND",
    #   "Body"=>"",
    #   "FromCountry"=>"US",
    #   "To"=>"+13869511980",
    #   "ToZip"=>"32763",
    #   "NumSegments"=>"3",
    #   "MessageSid"=>"MMa87e504535c5c7587c2aae14a149fa93",
    #   "AccountSid"=>"AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8",
    #   "From"=>"+18023455136",
    #   "NumMedia"=>"3",
    #   "MediaContentType0"=>"image/jpeg",
    #   "MediaContentType1"=>"image/jpeg",
    #   "MediaContentType2"=>"image/jpeg",
    #   "MediaUrl0"=>"https://api.twilio.com/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Messages/MMa87e504535c5c7587c2aae14a149fa93/Media/ME6ef94da781562db11bdcaea870f23489",
    #   "MediaUrl1"=>"https://api.twilio.com/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Messages/MMa87e504535c5c7587c2aae14a149fa93/Media/ME755ee689bf4b8d4aa0af35fa0fe80bc9",
    #   "MediaUrl2"=>"https://api.twilio.com/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Messages/MMa87e504535c5c7587c2aae14a149fa93/Media/ME4384aa9ae8824c0fbf03bcec83039589",
    #   "ApiVersion"=>"2010-04-01"
    # }

    # {
    #   "ToCountry"=>"US",
    #   "ToState"=>"FL",
    #   "SmsMessageSid"=>"SMc5548af1fe8f5c1f44e62376b46e8b9a",
    #   "ToCity"=>"ORANGE CITY",
    #   "FromZip"=>"05701",
    #   "SmsSid"=>"SMc5548af1fe8f5c1f44e62376b46e8b9a",
    #   "FromState"=>"VT",
    #   "SmsStatus"=>"received",
    #   "FromCity"=>"RUTLAND",
    #   "Body"=>"Testing",
    #   "FromCountry"=>"US",
    #   "To"=>"+13869511980",
    #   "ToZip"=>"32763",
    #   "NumSegments"=>"1",
    #   "MessageSid"=>"SMc5548af1fe8f5c1f44e62376b46e8b9a",
    #   "AccountSid"=>"AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8",
    #   "From"=>"+18023455136",
    #   "NumMedia"=>"",
    #   "ApiVersion"=>"2010-04-01"
    # }

    # send a text message through Twilio
    # SMS::TwilioSms.send( from_phone, to_phone, message_text )
    def self.send(from_phone, to_phone, message_text = '', media_url_array = [], tenant = 'chiirp')
      message_text    = message_text.to_s.strip
      media_url_array = [] unless media_url_array.is_a?(Array)
      twilio_client   = self.twilio_client
      response        = {
        sid:           '',
        account_sid:   '',
        status:        'sent',
        cost:          0.0,
        num_segments:  0,
        error_code:    '',
        error_message: ''
      }

      if message_text.empty? && media_url_array.empty?
        # message text is empty
        response[:error_code]    = '21602'
        response[:error_message] = 'Message body is required.'
      else
        # message text is NOT empty

        response[:account_sid] = twilio_client.account_sid

        # send Twilio message
        begin
          retries ||= 0

          # message = twilio_client.messages.create(new_message)
          message_array = {
            status_callback: callback_url(tenant:),
            from:            "+1#{from_phone}",
            # from: "+13869511980",  # Live Twilio number
            # from: "+15005550001",  # Test number to return 21212 error response (number is invalid.)
            # from: "+15005550006",  # Test number to return proper response
            # from: "+15005550007",  # Test number to return 21606 error response (number is not owned by your account or is not SMS-capable.)
            # from: "+15005550008",  # Test number to return 21611 error response (number has an SMS message queue that is full.)
            to:              "+1#{to_phone}" # Live contact phone number
            # to: "+15005550001"  # Test number to return 21211 error response (number is invalid.)
            # to: "+15005550002"  # Test number to return 21612 error response (Twilio cannot route to this number.)
            # to: "+15005550003"  # Test number to return 21408 error response (account doesn't have the international permissions.)
            # to: "+15005550004"  # Test number to return 21610 error response (number is blacklisted for your account.)
            # to: "+15005550009"  # Test number to return 21614 error response (number is incapable of receiving SMS messages.)
          }
          message_array[:body]      = message_text
          message_array[:media_url] = media_url_array unless media_url_array.empty?

          message = twilio_client.messages.create(**message_array)

          response[:sid]           = message.sid
          response[:account_sid]   = message.account_sid
          response[:status]        = message.status
          response[:cost]          = message.price.to_d.abs
          response[:num_segments]  = message.num_segments.to_i
          response[:error_code]    = message.error_code
          response[:error_message] = message.error_message
        rescue Twilio::REST::RestError => e
          if e.message.casecmp?('execution expired') && (retries += 1) < 3
            response = {
              sid:           '',
              account_sid:   '',
              status:        'undelivered',
              cost:          0.0,
              num_segments:  0,
              error_code:    '',
              error_message: ''
            }

            retry
          end

          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          case response[:error_code].to_i
          when 21_211
            # to_phone is NOT valid / no need to log error
          when 21_408
            # Permission to send an SMS has not been enabled for the region indicated by the 'To' number
          when 21_610
            # From/To pair violates a blacklist rule / no need to log error
          when 21_614
            # to_phone is not a mobile number / no need to log error
          when 21_617
            # the concatenated message body exceeds the 1600 character limit / no need to log
          when 21_612
            # Unable to create record. The 'To' phone number: +1xxxxxxxxxx, is not currently reachable using the 'From' phone number: +1xxxxxxxxxx via SMS.
          when 21_606
            # The From phone number +1xxxxxxxxxx is not a valid, SMS-capable inbound phone number or short code for your account.
          else
            ProcessError::Report.send(
              error_message: "SMS::Send: #{e.message}",
              variables:     {
                e:               e.inspect,
                from_phone:      from_phone.inspect,
                media_url_array: media_url_array.inspect,
                message:         (defined?(message) ? message : nil),
                message_array:   message_array.inspect,
                message_text:    message_text.inspect,
                response:        response.inspect,
                retries:         retries.inspect,
                tenant:          tenant.inspect,
                to_phone:        to_phone.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        rescue Twilio::REST::TwilioError => e
          if e.message.downcase.include?('execution expired') && (retries += 1) < 3
            response = {
              sid:           '',
              account_sid:   '',
              status:        'undelivered',
              cost:          0.0,
              num_segments:  0,
              error_code:    '',
              error_message: ''
            }

            retry
          end

          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          ProcessError::Report.send(
            error_message: "SMS::Send: #{e.message}",
            variables:     {
              e:               e.inspect,
              e_message:       e.message.inspect,
              from_phone:,
              media_url_array: media_url_array.inspect,
              message_text:,
              response:        response.inspect,
              retries:         retries.inspect,
              to_phone:
            },
            file:          __FILE__,
            line:          __LINE__
          )
        rescue StandardError => e
          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          ProcessError::Report.send(
            error_message: "SMS::Send: #{e.message}",
            variables:     {
              e:               e.inspect,
              from_phone:,
              media_url_array: media_url_array.inspect,
              message_text:,
              response:        response.inspect,
              retries:         retries.inspect,
              to_phone:
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      response
    end
    # {
    #   "account_sid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "api_version": "2010-04-01",
    #   "body": "This is the ship that made the Kessel Run in fourteen parsecs?",
    #   "date_created": "Thu, 30 Jul 2015 20:12:31 +0000",
    #   "date_sent": "Thu, 30 Jul 2015 20:12:33 +0000",
    #   "date_updated": "Thu, 30 Jul 2015 20:12:33 +0000",
    #   "direction": "outbound-api",
    #   "error_code": null,
    #   "error_message": null,
    #   "from": "+15017122661",
    #   "messaging_service_sid": null,
    #   "num_media": "",
    #   "num_segments": "1",
    #   "price": "-0.00750",
    #   "price_unit": "USD",
    #   "sid": "MMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "status": "sent",
    #   "subresource_uris": {
    #     "media": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Messages/SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Media.json"
    #   },
    #   "to": "+15558675310",
    #   "uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Messages/SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.json"
    # }

    def self.twilio_client
      Twilio::REST::Client.new(
        Rails.application.credentials[:twilio][:sid],
        Rails.application.credentials[:twilio][:auth]
      )
    end

    # update status for a specific Messages::Message from Twilio
    # SMS::TwilioSms.update_status(Messages::Message)
    def self.update_status(message)
      twilio_client = self.twilio_client
      response      = { success: true, error_code: '', error_message: '', message_response: nil }

      return response if message.message_sid.to_s.blank?

      if Messages::Message::MSG_TYPES_VOICE.include?(message.msg_type)
        # voice call
        updates = {
          cost:         BigDecimal(0),
          message:      message.message,
          num_segments: 0
        }

        begin
          retries ||= 0

          call_result = twilio_client.calls(message.message_sid).fetch

          updates[:cost]           += call_result.price.to_s.to_d.abs
          updates[:message]        += " (length: #{ActionController::Base.helpers.distance_of_time_in_words(Time.now.utc, Time.now.utc + call_result.duration.to_i.seconds, { include_seconds: true })})" unless updates[:message].include?('(length: ')
          updates[:num_segments]   += call_result.duration.to_i

          Voice::TwilioVoice.get_child_calls(parent_sid: message.message_sid).each do |child|
            updates[:cost]         += child[:price]
            updates[:num_segments] += child[:call_duration]
          end

          if message.num_segments.zero? && updates[:num_segments].positive? && message.created_at >= Time.zone.parse('2020-05-20')
            # this is the first time we received the length of the call from Twilio / let's bill the Client
            message.contact.client.charge_for_action(key: 'phone_call_credits', multiplier: updates[:num_segments], contact_id: message.contact.id, message_id: message.id)
          end

          call_result.subresource_uris.each do |type, resource|
            next unless type == 'recordings'

            conn = Faraday.new(url: "https://#{Rails.application.credentials[:twilio][:sid]}:#{Rails.application.credentials[:twilio][:auth]}@api.twilio.com" + resource)
            recording_result = conn.get

            JSON.parse(recording_result.body)['recordings'].each do |recording|
              updates[:cost] += recording['price'].to_s.to_d.abs

              recording['subresource_uris'].each do |subtype, subresource|
                next unless subtype == 'transcriptions'

                conn = Faraday.new(url: "https://#{Rails.application.credentials[:twilio][:sid]}:#{Rails.application.credentials[:twilio][:auth]}@api.twilio.com" + subresource)
                transcription_result = conn.get

                JSON.parse(transcription_result.body)['transcriptions'].each do |transcription|
                  updates[:cost] += transcription['price'].to_s.to_d.abs
                end
              end
            end
          end

          message.update(updates)
        rescue Twilio::REST::TwilioError => e
          if e.message.casecmp?('execution expired') && (retries += 1) < 3
            response = { success: true, error_code: '', error_message: '', message_response: nil }
            updates  = {
              cost:         BigDecimal(0),
              message:      message.message,
              num_segments: 0
            }

            retry
          end

          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          ProcessError::Report.send(
            error_message: "SMS::UpdateStatus: #{e.message}",
            variables:     {
              call_result:                                  defined?(call_result) ? call_result.inspect : 'Undefined',
              call_result_subresource_uris:                 defined?(call_result.subresource_uris) ? call_result.subresource_uris.inspect : 'Undefined',
              recording_result:                             defined?(recording_result) ? recording_result.inspect : 'Undefined',
              recording_result_body:                        defined?(recording_result.body) ? JSON.parse(recording_result.body).inspect : 'Undefined',
              e:                                            e.inspect,
              response:                                     response.inspect,
              retries:                                      retries.inspect,
              transcription_result:                         defined?(transcription_result) ? transcription_result.inspect : 'Undefined',
              transcription_result_body:                    defined?(transcription_result.body) ? JSON.parse(transcription_result.body).inspect : 'Undefined',
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              message:                                      message.inspect,
              updates:                                      updates.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        rescue StandardError => e
          if e.message.casecmp?('execution expired') && (retries += 1) < 3
            response = { success: true, error_code: '', error_message: '', message_response: nil }
            updates  = {
              cost:         BigDecimal(0),
              message:      message.message,
              num_segments: 0
            }

            retry
          end

          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          ProcessError::Report.send(
            error_message: "SMS::UpdateStatus: #{e.message}",
            variables:     {
              call_result:                                  defined?(call_result) ? call_result.inspect : 'Undefined',
              call_result_subresource_uris:                 defined?(call_result.subresource_uris) ? call_result.subresource_uris.inspect : 'Undefined',
              recording_result:                             defined?(recording_result) ? recording_result.inspect : 'Undefined',
              recording_result_body:                        defined?(recording_result.body) ? JSON.parse(recording_result.body).inspect : 'Undefined',
              e:                                            e.inspect,
              response:                                     response.inspect,
              retries:                                      retries.inspect,
              transcription_result:                         defined?(transcription_result) ? transcription_result.inspect : 'Undefined',
              transcription_result_body:                    defined?(transcription_result.body) ? JSON.parse(transcription_result.body).inspect : 'Undefined',
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              message:                                      message.inspect,
              updates:                                      updates.inspect
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      elsif Messages::Message::MSG_TYPES_VIDEO.include?(message.msg_type) && message.status != 'room-ended'
        # video is most likely in progress

      else
        # text message
        begin
          retries ||= 0
          updates   = {}

          response[:message_response] = twilio_client.messages(message.message_sid).fetch

          updates[:status]            = response[:message_response].status if message.status.to_s.empty? && response[:message_response].status.to_s.present?
          updates[:cost]              = response[:message_response].price.to_d.abs
          updates[:num_segments]      = response[:message_response].num_segments.to_i
          updates[:error_code]        = response[:message_response].error_code
          updates[:error_message]     = response[:message_response].error_message

          message.update(updates)
        rescue Twilio::REST::RestError => e
          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          if response[:error_code].to_i == 20_404
            ProcessError::Report.send(
              error_code:    response[:error_code],
              error_message: 'SMS::UpdateStatus: The requested resource was not found.',
              variables:     {
                e:                                            e.inspect,
                response:                                     response.inspect,
                retries:                                      retries.inspect,
                message:                                      message.inspect,
                twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
                updates:                                      defined?(updates) ? updates.inspect : 'Undefined'
              },
              file:          __FILE__,
              line:          __LINE__
            )
          else
            ProcessError::Report.send(
              error_message: "SMS::UpdateStatus: #{e.message}",
              variables:     {
                e:                                            e.inspect,
                response:                                     response.inspect,
                retries:                                      retries.inspect,
                message:                                      message.inspect,
                twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
                updates:                                      defined?(updates) ? updates.inspect : 'Undefined'
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end
        rescue Twilio::REST::TwilioError => e
          retry if e.message.casecmp?('execution expired') && (retries += 1) < 3

          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          ProcessError::Report.send(
            error_message: "SMS::UpdateStatus: #{e.message}",
            variables:     {
              e:                                            e.inspect,
              response:                                     response.inspect,
              retries:                                      retries.inspect,
              message:                                      message.inspect,
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              updates:                                      defined?(updates) ? updates.inspect : 'Undefined'
            },
            file:          __FILE__,
            line:          __LINE__
          )
        rescue StandardError => e
          response[:error_code]    = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('code').to_s : 'Undefined'
          response[:error_message] = defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.dig('message').to_s : 'Undefined'

          ProcessError::Report.send(
            error_message: "SMS::UpdateStatus: #{e.message}",
            variables:     {
              e:                                            e.inspect,
              response:                                     response.inspect,
              retries:                                      retries.inspect,
              message:                                      message.inspect,
              twilio_client_http_client_last_response_body: defined?(twilio_client.http_client.last_response.body) ? twilio_client.http_client.last_response.body.inspect : 'Undefined',
              updates:                                      defined?(updates) ? updates.inspect : 'Undefined'
            },
            file:          __FILE__,
            line:          __LINE__
          )
        end
      end

      response
    end
    #
    # voice call response
    #
    # {
    #   account_sid: AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8
    #   annotation:
    #   answered_by:
    #   api_version: 2010-04-01
    #   caller_name:
    #   date_created: 2019-11-25 17:17:10 +0000
    #   date_updated: 2019-11-25 17:17:49 +0000
    #   direction: inbound
    #   duration: 38
    #   end_time: 2019-11-25 17:17:49 +0000
    #   forwarded_from: +18025001302
    #   from: +18027791581
    #   from_formatted: (802) 779-1581
    #   group_sid:
    #   parent_call_sid:
    #   phone_number_sid: PN3cededd7ddfb0a14ba7a37671e10902d
    #   price: -0.00765
    #   price_unit: USD
    #   sid: CA6fed712ea03c9debd3a7c1e48d90ace4
    #   start_time: 2019-11-25 17:17:11 +0000
    #   status: completed
    #   subresource_uris: {
    #     "notifications": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA6fed712ea03c9debd3a7c1e48d90ace4/Notifications.json"
    #     "recordings": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA6fed712ea03c9debd3a7c1e48d90ace4/Recordings.json"
    #   }
    #   to: +18025001302
    #   to_formatted: (802) 500-1302
    #   uri: /2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA6fed712ea03c9debd3a7c1e48d90ace4.json
    # }
    #
    # text message response
    #
    # {
    #   "account_sid": "ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "api_version": "2010-04-01",
    #   "body": "testing",
    #   "date_created": "Fri, 24 May 2019 17:18:27 +0000",
    #   "date_sent": "Fri, 24 May 2019 17:18:28 +0000",
    #   "date_updated": "Fri, 24 May 2019 17:18:28 +0000",
    #   "direction": "outbound-api",
    #   "error_code": 30007,
    #   "error_message": "Carrier violation",
    #   "from": "+12019235161",
    #   "messaging_service_sid": "MGXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "num_media": "",
    #   "num_segments": "1",
    #   "price": "-0.00750",
    #   "price_unit": "USD",
    #   "sid": "MMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
    #   "status": "accepted / queued / sending / sent / receiving / received / delivered / undelivered / failed",
    #   "subresource_uris": {
    #     "media": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Messages/SMb7c0a2ce80504485a6f653a7110836f5/Media.json",
    #     "feedback": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Messages/SMb7c0a2ce80504485a6f653a7110836f5/Feedback.json"
    #   },
    #   "to": "+18182008801",
    #   "uri": "/2010-04-01/Accounts/ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/Messages/SMb7c0a2ce80504485a6f653a7110836f5.json"
    # }
    #
    # notifications response
    #
    # {
    #   "first_page_uri": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA09860973c3c84b6201ed0077f880233d/Notifications.json?PageSize=50&Page=0",
    #   "end": 0,
    #   "previous_page_uri": null,
    #   "uri": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA09860973c3c84b6201ed0077f880233d/Notifications.json?PageSize=50&Page=0",
    #   "page_size": 50,
    #   "page": 0,
    #   "notifications": [],
    #   "next_page_uri": null,
    #   "start": 0
    # }
    #
    # recordings response
    #
    # {
    #   "first_page_uri": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA09860973c3c84b6201ed0077f880233d/Recordings.json?PageSize=50&Page=0",
    #   "end": 0,
    #   "previous_page_uri": null,
    #   "uri": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Calls/CA09860973c3c84b6201ed0077f880233d/Recordings.json?PageSize=50&Page=0",
    #   "page_size": 50,
    #   "start": 0,
    #   "recordings": [
    #     {
    #       "account_sid": "AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8",
    #       "api_version": "2010-04-01",
    #       "call_sid": "CA09860973c3c84b6201ed0077f880233d",
    #       "conference_sid": null,
    #       "date_created": "Mon, 25 Nov 2019 19:02:15 +0000",
    #       "date_updated": "Mon, 25 Nov 2019 19:02:19 +0000",
    #       "start_time": "Mon, 25 Nov 2019 19:02:15 +0000",
    #       "duration": "4",
    #       "sid": "REdfc3d85186fafd54224408f79427ff2a",
    #       "price": "-0.00250",
    #       "price_unit": "USD",
    #       "status": "completed",
    #       "channels": 1,
    #       "source": "RecordVerb",
    #       "error_code": null,
    #       "uri": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Recordings/REdfc3d85186fafd54224408f79427ff2a.json",
    #       "encryption_details": null,
    #       "subresource_uris": {
    #           "add_on_results": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Recordings/REdfc3d85186fafd54224408f79427ff2a/AddOnResults.json",
    #           "transcriptions": "/2010-04-01/Accounts/AC4af9e2c0a8ed64f5b8d9a8f1fdde90b8/Recordings/REdfc3d85186fafd54224408f79427ff2a/Transcriptions.json"
    #       }
    #     }
    #   ],
    #   "next_page_uri": null,
    #   "page": 0
    # }

    def self.url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def self.url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end
  end
end
