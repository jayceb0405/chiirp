# frozen_string_literal: true

# app/lib/SMS/bandwidth.rb
module SMS
  module Bandwidth
    BANDWIDTH_2FA_APPLICATION_ID = '5d38ddb3-66ee-41ac-ba47-756cdea6a7be'

    # retrieves a media file from Bandwidth and stores it in ContactAttachment
    # SMS::Bandwidth.attach_media_to_contact(contact: Contact, media: String)
    def self.attach_media_to_contact(args = {})
      contact            = args.dig(:contact)
      media              = args.dig(:media).to_s

      return nil unless contact.is_a?(Contact) && media.present?

      media_id = self.get_media_id(media)
      filename = self.get_media_filename(media)

      return nil if filename == '0.smil'

      contact_attachment = nil

      Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        retry_skip_reason:     'getaddrinfo: Name or service not known',
        error_message_prepend: 'SMS::Bandwidth::AttachMediaToContact',
        current_variables:     {
          args:               args.inspect,
          contact_attachment: contact_attachment.inspect,
          filename:           filename.inspect,
          media:              media.inspect,
          media_id:           media_id.inspect,
          contact:            contact.inspect,
          parent_file:        __FILE__,
          parent_line:        __LINE__
        }
      ) do
        result = Faraday.get("#{self.base_messaging_url}media/#{media_id}") do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.headers['Authorization'] = "Basic #{self.basic_auth}"
        end

        if result.success?

          f = File.open(filename, 'wb')
          f.puts(result.body)
          f.close

          if File.exist?(filename)
            contact_attachment = contact.contact_attachments.create!(remote_image_url: filename)

            File.delete(filename)
          end
        end
      end

      contact_attachment
    end

    # process a callback from Bandwidth
    # message types: message-delivered / message-failed
    def self.message_callback(**args)
      args     = args&.dig(:_json)
      response = {
        success:       false,
        message_sid:   '',
        status:        '',
        error_code:    0,
        error_message: ''
      }

      if args.is_a?(Array) && args.present?
        args     = args[0]
        response = {
          success:       true,
          message_sid:   args.dig(:message, :id).to_s,
          status:        args.dig(:type).to_s.gsub('message-', ''),
          error_code:    args.dig(:errorCode).to_i,
          error_message: (args.dig(:errorCode).to_i.positive? ? args.dig(:description).to_s.tr('-', ' ').titleize : '')
        }
      end

      response
    end
    # {
    #   "_json"=>[
    #     {
    #       "time"=>"2021-03-03T00:30:50.637Z",
    #       "type"=>"message-failed",
    #       "to"=>"+18022592292",
    #       "description"=>"invalid-destination-address",
    #       "message"=>{
    #         "id"=>"1614731449657qemvwcch2wqgqojf",
    #         "owner"=>"+18022898010",
    #         "applicationId"=>"5e8b5ec9-65bf-4342-a18e-27b3fc355e65",
    #         "time"=>"2021-03-03T00:30:49.657Z",
    #         "segmentCount"=>1,
    #         "direction"=>"out",
    #         "to"=>["+18022592292"],
    #         "from"=>"+18022898010",
    #         "text"=>"",
    #         "tag"=>""
    #       },
    #       "errorCode"=>4720
    #     }
    #   ],
    #   "message"=>{}
    # }

    # receive params from Bandwidth incoming message webhook
    # message = SMS::Bandwidth.receive(params)
    #
    # Required Parameters:
    #   to:      (String)
    #   message: (Hash)
    #     from:  (String)
    #     text:  (String)
    #
    # Optional Parameters:
    #   applicationId: (String)
    #   message:       (Hash)
    #     id:          (String)
    #     media:       (Array)
    #   segmentCount:  (String)
    #   type:          (String)
    def self.receive(args = {})
      args     = args.dig(:_json)
      response = {
        success:       false,
        message:       {
          from_phone:    '',
          to_phone:      '',
          content:       '',
          media_array:   [],
          segment_count: 0,
          status:        'failed',
          message_sid:   '',
          account_sid:   '',
          to_city:       '',
          to_state:      '',
          to_zip:        '',
          to_country:    '',
          from_city:     '',
          from_state:    '',
          from_zip:      '',
          from_country:  ''
        },
        error_code:    '',
        error_message: ''
      }

      if args.is_a?(Array) && args.present?
        args                            = args[0]
        response[:message][:to_phone]   = args.dig(:to).to_s
        response[:message][:from_phone] = args.dig(:message, :from).to_s
        response[:message][:content]    = args.dig(:message, :text).to_s

        if response[:message][:to_phone].empty?
          response[:error_message] = 'Expected \'To Phone\' missing.'
        elsif response[:message][:from_phone].empty?
          response[:error_message] = 'Expected \'From Phone\' missing.'
        else
          response[:success]                 = true
          response[:message][:segment_count] = [args.dig(:message, :segmentCount).to_i, 1].max
          response[:message][:status]        = (args.dig(:type) || 'received').to_s.gsub('message-', '')
          response[:message][:message_sid]   = args.dig(:message, :id).to_s
          response[:message][:account_sid]   = self.application_id

          if args.dig(:message, :media).present?

            args.dig(:message, :media).each do |m|
              response[:message][:media_array] << m
            end
          end
        end
      end

      response
    end
    # {
    #   "_json"=>[
    #     {
    #       "time"=>"2021-03-03T09:45:15.964Z",
    #       "type"=>"message-received",
    #       "to"=>"+18022898010",
    #       "description"=>"Incoming message received",
    #       "message"=>{
    #         "id"=>"421aaa7d-4be8-4cbb-9914-ff3aec2c3050",
    #         "owner"=>"+18022898010",
    #         "applicationId"=>"5e8b5ec9-65bf-4342-a18e-27b3fc355e65",
    #         "time"=>"2021-03-03T09:45:15.861Z",
    #         "segmentCount"=>1,
    #         "direction"=>"in",
    #         "to"=>["+18022898010"],
    #         "from"=>"+18023455136",
    #         "text"=>"Incoming 01",
    #         "media"=>[
    #           "https://messaging.bandwidth.com/api/v2/users/5007421/media/f612f6b1-20d2-4855-bbb0-d060231e7561/0/0.smil",
    #           "https://messaging.bandwidth.com/api/v2/users/5007421/media/f612f6b1-20d2-4855-bbb0-d060231e7561/1/IMG_4099.png"
    #         ]
    #       }
    #     }
    #   ],
    #   "message"=>{}
    # }

    # send a text message through Bandwidth
    # SMS::Bandwidth.send(from_phone, to_phone, message_text, media_url_array, tenant)
    #
    # Required Arguments:
    #   from_phone:      (String)
    #   to_phone:        (String)
    #   message_text:    (String)
    #
    # Optional Arguments:
    #   media_url_array: (Array)
    #   tenant:          (String)
    #   two_factor:      (Boolean)
    def self.send(from_phone, to_phone, message_text = '', media_url_array = [], tenant = 'chiirp', two_factor = false)
      message_text    = message_text.to_s.strip
      media_url_array = [] unless media_url_array.is_a?(Array)
      app_id = two_factor ? BANDWIDTH_2FA_APPLICATION_ID : self.application_id
      response = {
        sid:           '',
        account_sid:   app_id,
        status:        'sent',
        cost:          0.0,
        num_segments:  0,
        error_code:    '',
        error_message: ''
      }

      if message_text.empty? && media_url_array.empty?
        response[:error_code]    = '21602'
        response[:error_message] = 'Message body is required.'
      else

        _x, response[:error_code], response[:error_message] = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          retry_skip_reason:     'getaddrinfo: Name or service not known',
          error_message_prepend: 'SMS::Bandwidth::Send',
          current_variables:     {
            from_phone:,
            media_url_array: media_url_array.inspect,
            message_text:,
            to_phone:,
            tenant:,
            parent_file:     __FILE__,
            parent_line:     __LINE__
          }
        ) do
          data = {
            to:            ["+1#{to_phone}"],
            from:          "+1#{from_phone}",
            text:          message_text,
            applicationId: app_id
          }

          data[:media] = media_url_array unless media_url_array.empty?

          result = Faraday.post("#{self.base_messaging_url}messages") do |req|
            req.headers['Content-Type']  = 'application/json; charset=utf-8'
            req.headers['Authorization'] = "Basic #{self.basic_auth}"
            req.body                     = data.to_json
          end

          if result.success?
            data = JSON.parse(result.body)
            response[:sid]           = data['id']
            response[:account_sid]   = app_id
            response[:status]        = (result.status == 202 ? 'accepted' : '')
            response[:cost]          = 0.0
            response[:num_segments]  = data['segmentCount'].to_i
            response[:error_code]    = ''
            response[:error_message] = ''
          elsif result.status.to_i == 429
            # Bandwidth response: "Too Many Requests"
            ProcessError::Report.send(
              error_message: "Bandwidth::Send: #{result.reason_phrase}",
              variables:     {
                data:            data.inspect,
                from_phone:,
                media_url_array: media_url_array.inspect,
                message_text:,
                result:          result.inspect,
                result_methods:  result.methods.inspect,
                to_phone:,
                tenant:
              },
              file:          __FILE__,
              line:          __LINE__
            )
          else
            JsonLog.info 'Bandwidth::Send', { failed: true, result: }
          end
        end
      end

      response
    end
    # result.status: 202
    # result.success?: true
    # result.reason_phrase: "Accepted"
    # JSON.parse(result.body)
    # {
    #   "id"=>"1615212806959wc6y3wzzntt4hvht",
    #   "owner"=>"+18022898010",
    #   "applicationId"=>"5e8b5ec9-65bf-4342-a18e-27b3fc355e65",
    #   "time"=>"2021-03-08T14:13:26.959Z",
    #   "segmentCount"=>1,
    #   "direction"=>"out",
    #   "to"=>["+18023455136"],
    #   "from"=>"+18022898010",
    #   "text"=>"Hey, check this out!",
    #   "tag"=>"test message"
    # }

    # update status for a specific Messages::Message from Bandwidth
    # SMS::Bandwidth.update_status Messages::Message
    def self.update_status(message)
      response = { success: true, error_code: '', error_message: '', message_response: nil }

      if message.message_sid.to_s.present?
        updates = {
          status:        '',
          cost:          BigDecimal(0),
          num_segments:  0,
          error_code:    0,
          error_message: '',
          message:       message.message
        }

        if Messages::Message::MSG_TYPES_VOICE.include?(message.msg_type)
          # voice call

        elsif Messages::Message::MSG_TYPES_VIDEO.include?(message.msg_type) && message.status != 'room-ended'
          # video is most likely in progress

        else
          # text message

          _x, response[:error_code], response[:error_message] = Retryable.with_retries(
            rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
            retry_skip_reason:     'getaddrinfo: Name or service not known',
            error_message_prepend: 'SMS::Bandwidth::UpdateStatus',
            current_variables:     {
              message:     message.inspect,
              response:    response.inspect,
              parent_file: __FILE__,
              parent_line: __LINE__
            }
          ) do
            result = Faraday.get("#{self.base_messaging_url}messages?messageId=#{message.message_sid}") do |req|
              req.headers['Content-Type']  = 'application/json; charset=utf-8'
              req.headers['Authorization'] = "Basic #{self.basic_auth}"
            end

            if result.success?
              response[:message_response] = JSON.parse(result.body)

              response[:message_response]['messages'].each do |m|
                updates[:status]            = m['messageStatus'].downcase if message.status.to_s.empty? && m['messageStatus'].to_s.present?
                updates[:cost]              = 0.0
                updates[:num_segments]      = message['segmentCount'].to_i
                updates[:error_code]        = message['errorCode'].to_i
                updates[:error_message]     = ''

                message.update(updates)
              end
            end
          end
        end
      end

      response
    end
    # inbound text message response
    # <Bandwidth::ApiResponse:0x00007faadf342678
    #   @status_code=200,
    #   @reason_phrase="",
    #   @headers={
    #     "date"=>"Wed, 03 Mar 2021 21:58:20 GMT",
    #     "content-type"=>"application/json",
    #     "content-length"=>"347",
    #     "connection"=>"keep-alive",
    #     "strict-transport-security"=>"max-age=31536000 ; includeSubDomains",
    #     "cache-control"=>"no-cache, no-store, max-age=0, must-revalidate",
    #     "pragma"=>"no-cache",
    #     "expires"=>"0",
    #     "x-content-type-options"=>"nosniff",
    #     "x-frame-options"=>"DENY",
    #     "x-xss-protection"=>"1 ; mode=block", "referrer-policy"=>"no-referrer"
    #   },
    #   @raw_body="{\"totalCount\":1,\"pageInfo\":{},\"messages\":[{\"messageId\":\"55ab770c-da85-468b-8512-dd196106f4f8\",\"accountId\":\"5007421\",\"sourceTn\":\"+18023455136\",\"destinationTn\":\"+18022898010\",\"messageStatus\":\"ACCEPTED\",\"messageDirection\":\"INBOUND\",\"messageType\":\"sms\",\"segmentCount\":1,\"errorCode\":0,\"carrierName\":\"Verizon\",\"receiveTime\":\"2021-03-03T10:15:41.421Z\"}]}",
    #   @request=#<Bandwidth::HttpRequest:0x00007faadf350ca0
    #     @http_method="GET",
    #     @query_url="https://messaging.bandwidth.com/api/v2/users/5007421/messages?messageId=55ab770c-da85-468b-8512-dd196106f4f8",
    #     @headers={
    #       "accept"=>"application/json",
    #       "Authorization"=>"Basic YXBpX2FjY2Vzc0BrZXZpbm5ldWJlcnQuY29tOlJAdjZ2eW5MUW80ajdfRUxhQmd4",
    #       "user-agent"=>"ruby-sdk"
    #     },
    #     @parameters={}
    #   >,
    #   @data=#<Bandwidth::BandwidthMessagesList:0x00007faadf3426c8
    #     @total_count=1,
    #     @page_info=#<Bandwidth::PageInfo:0x00007faadf342740
    #       @prev_page=nil,
    #       @next_page=nil,
    #       @prev_page_token=nil,
    #       @next_page_token=nil
    #     >,
    #     @messages=[
    #       #<Bandwidth::BandwidthMessageItem:0x00007faadf3426f0
    #         @message_id="55ab770c-da85-468b-8512-dd196106f4f8",
    #         @account_id="5007421",
    #         @source_tn="+18023455136",
    #         @destination_tn="+18022898010",
    #         @message_status="ACCEPTED",
    #         @message_direction="INBOUND",
    #         @message_type="sms",
    #         @segment_count=1,
    #         @error_code=0,
    #         @receive_time="2021-03-03T10:15:41.421Z",
    #         @carrier_name="Verizon"
    #       >
    #     ]
    #   >,
    #   @errors=nil
    # >

    # outbound text message response
    # {
    #   "totalCount"=>1,
    #   "pageInfo"=>{},
    #   "messages"=>[
    #     {
    #       "messageId"=>"1615243743475srzxar5snirv6jqe",
    #       "accountId"=>"5007421",
    #       "sourceTn"=>"+18022898010",
    #       "destinationTn"=>"+18023455136",
    #       "messageStatus"=>"DELIVERED",
    #       "messageDirection"=>"OUTBOUND",
    #       "messageType"=>"mms",
    #       "segmentCount"=>1,
    #       "errorCode"=>0,
    #       "carrierName"=>"Verizon",
    #       "receiveTime"=>"2021-03-08T22:49:04.227Z"
    #     }
    #   ]
    # }

    def self.account_id
      Rails.application.credentials[:bandwidth][:account_id]
    end

    def self.application_id
      ENV.fetch('BANDWIDTH_MESSAGING_APPLICATION_ID', nil)
    end

    def self.base_messaging_url
      "https://messaging.bandwidth.com/api/v2/users/#{self.account_id}/"
    end

    def self.basic_auth
      Base64.urlsafe_encode64("#{Rails.application.credentials[:bandwidth][:user_name]}:#{Rails.application.credentials[:bandwidth][:password]}").strip
    end

    # Takes a full media url from Bandwidth and extracts the filename
    # @param media_url [String] The full media url
    # @returns [String] The media file name
    def self.get_media_filename(media_url)
      media_url.split('/').last
    end

    # Takes a full media url from Bandwidth and extracts the media id
    # The full media url looks like https://messaging.bandwidth.com/api/v2/users/123/media/<media_id>
    #     where <media_id> can be of format <str>/<int>/<str> or <str>
    # Example: https://messaging.bandwidth.com/api/v2/users/123/media/file.png
    #          https://messaging.bandwidth.com/api/v2/users/123/media/abc/0/file.png
    # @param media_url [String] The full media url
    # @returns [String] The media id
    def self.get_media_id(media_url)
      split_url = media_url.split('/')
      split_url[split_url.index('media') + 1, split_url.length - 1].join('/')
    end

    def self.put_result(result)
      Rails.logger.info "result.success?: #{result.success?.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "result.status: #{result.status.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "result.reason_phrase: #{result.reason_phrase.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }" if defined?(result.reason_phrase)
      Rails.logger.info "result.public_methods: #{result.public_methods.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "result.body: #{result.body.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      Rails.logger.info "ActiveSupport::XmlMini.parse(result.body): #{ActiveSupport::XmlMini.parse(result.body).inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
    end

    def self.sub_account_id(tenant)
      I18n.with_locale(tenant) { I18n.t("tenant.#{Rails.env}.bandwidth.subaccount_id") }
    end

    def self.url_host
      I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") }
    end

    def self.url_protocol
      I18n.with_locale('chiirp') { I18n.t('tenant.app_protocol') }
    end
  end
end
