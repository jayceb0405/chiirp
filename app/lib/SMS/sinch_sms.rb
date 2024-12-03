# frozen_string_literal: true

# app/lib/SMS/sinch_sms.rb
module SMS
  # methods used to support SMS.MMS messaging through Sinch
  class SinchSms
    attr_reader :error, :faraday_result, :message, :result

    # initialize SMS::Sinch object
    # si_client = SMS::SinchSms.new()
    # (opt) callback_urlL (String)
    def initialize(args = {})
      reset_attributes
      @callback_url = args.dig(:callback_url).to_s
    end

    # process a callback from Bandwidth
    # SMS::SinchSms.new.message_callback()
    def message_callback(args = {})
      if args.is_a?(ActionController::Parameters) && args.present?
        {
          success:       true,
          message_sid:   args.dig(:batch_id).to_s,
          status:        args.dig(:status).to_s.downcase,
          error_code:    args.dig(:code).to_i,
          error_message: ''
        }
      else
        {
          success:       false,
          message_sid:   '',
          status:        '',
          error_code:    0,
          error_message: ''
        }
      end
    end
    # Callback parameters
    # {
    #   "at"=>"2022-09-26T13:56:10.111Z",
    #   "batch_id"=>"01GDX1AVTDA1EX1MR2A69A1E7Q",
    #   "code"=>0,
    #   "operator_status_at"=>"2022-09-26T13:56:00Z",
    #   "recipient"=>"18023455136",
    #   "status"=>"Delivered",
    #   "type"=>"recipient_delivery_report_sms",
    #   "controller"=>"messages",
    #   "action"=>"msg_callback",
    #   "message"=>{
    #     "status"=>"Delivered"
    #   }
    # }

    # receive params from Sinch incoming message webhook
    # message = SMS::SinchSms.receive(params)
    #
    # Arguments:
    #   (req) to:      (String)
    #   (req) message: (Hash)
    #     from:  (String)
    #     text:  (String)
    #   (opt) applicationId: (String)
    #   (opt) message:       (Hash)
    #     id:          (String)
    #     media:       (Array)
    #   (opt) segmentCount:  (String)
    #   (opt) type:          (String)
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

    # send a text message through Sinch
    # SMS::SinchSms.send(from_phone, to_phone, message_text, media_url_array)
    #
    # Arguments:
    #   (req) from_phone:      (String)
    #   (req) to_phone:        (String)
    #   (req) message_text:    (String)
    #   (opt) media_url_array: (Array)
    #
    def send(from_phone, to_phone, message_text = '', media_url_array = [])
      reset_attributes
      message_text    = message_text.to_s.strip
      media_url_array = [] unless media_url_array.is_a?(Array)
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
        response[:error_code]    = '21602'
        response[:error_message] = 'Message body is required.'
      else
        body = {
          from:            from_phone,
          to:              [to_phone],
          body:            message_text,
          delivery_report: 'per_recipient'
        }
        body[:callback_url] = @callback_url if @callback_url.present?

        self.sinch_request(
          body:,
          error_message_prepend: 'SMS::SinchSms.Send',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "https://us.sms.api.sinch.com/xms/v1/#{self.service_plan_id}/batches"
        )

        if @result.dig(:id).present? && !@result.dig(:canceled).to_bool
          response[:sid]           = @result[:id].to_s
          response[:account_sid]   = self.service_plan_id
          response[:status]        = @result.dig(:cancelled).to_bool ? 'accepted' : ''
          response[:cost]          = 0.0
          response[:num_segments]  = 0
          response[:error_code]    = ''
          response[:error_message] = ''
        else
          JsonLog.info 'SMS::SinchSms::Send', { failed: true, result: @result }
        end
      end

      response
    end
    # @result
    # {
    #   :id=>"01GDX0VTGCCJYY0WMQRNCT107K",
    #   :to=>["18023455136"],
    #   :from=>"12064743966",
    #   :canceled=>false,
    #   :body=>"This is a test message for Sinch. Reply 'Stop' to stop",
    #   :type=>"mt_text",
    #   :created_at=>"2022-09-26T13:47:55.788Z",
    #   :modified_at=>"2022-09-26T13:47:55.788Z",
    #   :delivery_report=>"per_recipient",
    #   :expire_at=>"2022-09-29T13:47:55.788Z",
    #   :callback_url=>"https://dev.chiirp.com/message/msg_callback",
    #   :flash_message=>false
    # }

    def success?
      @success
    end

    private

    # self.sinch_request(
    #   body:                  Hash,
    #   error_message_prepend: 'Integrations::ServiceMonster.xxx',
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
            req.headers['Authorization'] = "Bearer #{api_token}"
            req.headers['Content-Type']  = 'application/json'
            req.params                   = params if params.present?
            req.body                     = body.to_json if body.present?
          end
        end

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

    def api_token
      Rails.application.credentials[:sinch][:api_token]
    end

    def key_id
      Rails.application.credentials[:sinch][:key_id]
    end

    def key_secret
      Rails.application.credentials[:sinch][:key_secret]
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

    def service_plan_id
      Rails.application.credentials[:sinch][:service_plan_id]
    end
  end
end
