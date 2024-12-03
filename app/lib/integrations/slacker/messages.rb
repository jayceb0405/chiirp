# frozen_string_literal: true

# app/lib/integrations/slacker/messages.rb
module Integrations
  module Slacker
    module Messages
      # call Slack API to post a message in a channel
      # slack_client.post_message(channel: String, content: String)
      def post_message(args = {})
        reset_attributes
        channel  = normalize_channel_name(args.dig(:channel))
        content  = args.dig(:content).to_s
        @result  = false

        if channel.blank?
          @message = 'Slack channel required'
          return @result
        elsif content.blank?
          @message = 'Message required'
          return @result
        elsif (channel = self.channel_create(channel)).blank?
          @message = 'Channel must be found in Slack workspace'
          return @result
        end

        body = {
          channel: channel.dig(:id).to_s,
          text:    content
        }

        slack_request(
          body:,
          error_message_prepend: 'Integrations::Slacker::Base.post_message',
          method:                'post',
          params:                nil,
          default_result:        {},
          url:                   "#{base_api_url}/chat.postMessage"
        )

        if @success && @result.is_a?(Hash)
          response = @result.dig(:ok).to_bool
        else
          response = false
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end

      def success?
        @success
      end
    end
  end
end
