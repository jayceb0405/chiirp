# frozen_string_literal: true

# app/lib/integrations/web_hook.rb
module Integrations
  class WebHook
    attr_reader :error, :message, :result

    # initialize Integrations::Webhook object
    # slack_client = Integrations::WebHook.new
    def initialize
      reset_attributes
      @result = nil
    end

    def send_json_to_url(url, data = {})
      reset_attributes
      @result = {}

      return @result unless url.to_s.valid_url?

      @success, @error, @message = Retryable.with_retries(
        rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
        error_message_prepend: 'Integrations::WebHook.send_json_to_url',
        current_variables:     {
          url:         url.inspect,
          data:        data.inspect,
          parent_file: __FILE__,
          parent_line: __LINE__
        }
      ) do
        result = Faraday.post(url) do |req|
          req.headers['Content-Type']  = 'application/json; charset=utf-8'
          req.body                     = data.to_json
        end

        if result.status == 200
          @success = true
          @result  = JSON.is_json?(result.body) ? JSON.parse(result.body).deep_symbolize_keys : {}
        else
          @message = 'Error received on sending JSON data.'
        end
      end

      @result
    end

    private

    def reset_attributes
      @error   = 0
      @message = ''
      @success = false
    end
  end
end
