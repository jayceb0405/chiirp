# frozen_string_literal: true

# app/lib/integrations/slacker/users.rb
module Integrations
  module Slacker
    module Users
      # call Slack API to find a user by email
      # slack_client.user_find_by_email(email)
      def user_find_by_email(email)
        reset_attributes
        email   = email.to_s
        @result = {}

        if email.blank?
          @message = 'Email required'
          return @result
        end

        slack_request(
          body:                  nil,
          error_message_prepend: 'Integrations::Slacker::Base.user_find_by_email',
          method:                'post',
          params:                { email: },
          default_result:        {},
          url:                   "#{base_api_url}/users.lookupByEmail"
        )

        if @success && @result.is_a?(Hash)
          response = @result.dig(:user) || {}
        else
          response = {}
          @success = false
          @message = "Unexpected response: #{@result.inspect}" if @message.blank?
        end

        @result = response
      end

      # call Slack API for a list of users
      # slack_client.users
      def users
        reset_attributes
        next_cursor = ''
        response    = []
        params      = {
          limit: 200
        }

        loop do
          params[:cursor] = next_cursor

          slack_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Slacker::Base.users',
            method:                'post',
            params:,
            default_result:        {},
            url:                   "#{base_api_url}/users.list"
          )

          if @success && @result.is_a?(Hash)
            response   += @result.dig(:members)
            next_cursor = @result.dig(:response_metadata, :next_cursor).to_s
            break if next_cursor.blank?
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}" if @message.blank?
            break
          end
        end

        @result = response
      end
    end
  end
end
