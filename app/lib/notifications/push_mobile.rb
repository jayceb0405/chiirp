# frozen_string_literal: true

# app/lib/notifications/push_mobile.rb
module Notifications
  class PushMobile
    class PushMobileError < StandardError; end

    # pm_client = Notifications::PushMobile.new(user_push_keys)
    #   (req) user_push_keys (Array)
    def initialize(user_push_keys)
      @user_push_keys = user_push_keys
    end

    # send push notification to mobile
    # pm_client.send_push()
    #   (opt) title:      (String)
    #   (opt) contact_id: (Integer)
    #   (opt) content:    (String)
    #   (opt) badge:      (Integer)
    #   (opt) type:       (String)
    #   (opt) url:        (String)
    def send_push(args = {})
      reset_attributes
      @result = false

      ignore_status = [406, 502, 503, 504]
      # 406 Not Acceptable (notifications met the rate limit)
      # 502 Bad Gateway (server errors)
      # 503 Service Temporarily Unavailable (server errors)
      # 504 Gateway Time-out (server errors)
      # push notifications are not considered to be essential / ignore

      return @result unless @user_push_keys.is_a?(Array) && @user_push_keys.present?

      @user_push_keys.each do |mobile_key|
        success, error, message = Retryable.with_retries(
          rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
          error_message_prepend: 'PushNotify::SendMobilePush',
          current_variables:     {
            args:           args.inspect,
            badge:          args.dig(:badge).inspect,
            contact_id:     args.dig(:contact_id).inspect,
            content:        args.dig(:content).inspect,
            mobile_key:     mobile_key.inspect,
            parent_file:    __FILE__,
            parent_line:    __LINE__,
            url:            args.dig(:url).inspect,
            title:          args.dig(:title).inspect,
            type:           args.dig(:type).inspect,
            user_push_keys: @user_push_keys.inspect
          }
        ) do
          message = if args.dig(:content).to_s.present? || args.dig(:title).to_s.present?
                      [{
                        to:    mobile_key,
                        sound: 'default',
                        badge: args.dig(:badge).to_i,
                        title: args.dig(:title).to_s,
                        body:  args.dig(:content).to_s,
                        data:  {
                          badge:      args.dig(:badge).to_i,
                          contact_id: args.dig(:contact_id).to_i,
                          message:    args.dig(:content).to_s,
                          title:      args.dig(:title).to_s,
                          type:       args.dig(:type).to_s,
                          url:        args.dig(:url).to_s
                        }
                      }]
                    else
                      [{
                        to:    mobile_key,
                        badge: args.dig(:badge).to_i
                      }]
                    end

          @faraday_result = Faraday.post(expo_base_url) do |req|
            req.headers['Content-Type']    = 'application/json'
            req.headers['Accept']          = 'application/json'
            req.headers['Accept-encoding'] = 'gzip, deflate'
            req.body                       = message.to_json
          end

          result_body = JSON.is_json?(@faraday_result.body) ? JSON.parse(@faraday_result.body).deep_symbolize_keys.dig(:data)&.first || {} : {}

          if @faraday_result.status == 200 && @faraday_result.reason_phrase.to_s.casecmp?('ok')

            if result_body.dig(:status).to_s.casecmp?('error') && result_body.dig(:details, :error).to_s == 'DeviceNotRegistered'
              UserPush.where('data @> ?', { mobile_key: }.to_json).destroy_all
            else
              @result  = true
              @success = true
            end
          elsif ignore_status.include?(@faraday_result.status)
            # ignore the result status
          else
            error = PushMobileError.new(@faraday_result.reason_phrase)
            error.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(error) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Notifications::PushMobile.send_push')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(args)

              Appsignal.set_tags(
                error_level: 'info',
                error_code:  @faraday_result.status
              )
              Appsignal.add_custom_data(
                ignore_status:,
                message:,
                result_body:,
                file:          __FILE__,
                line:          __LINE__
              )
            end
          end
        end

        @success = false unless success
        @error   = error
        @message = message if message.present?

        JsonLog.info 'PushNotify::SendMobilePush', { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
      end

      @result
    end

    def success?
      @success
    end

    private

    def expo_base_url
      'https://exp.host/--/api/v2/push/send'
    end

    def reset_attributes
      @error       = 0
      @message     = ''
      @success     = false
      @retry_count = 0
    end
  end
end
