# frozen_string_literal: true

# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    def session
      @request.session
    end

    protected

    def find_verified_user
      return env['warden'].user if env['warden'].user

      # use this method for authentication of clients without cookies
      # https://stackoverflow.com/questions/4361173/http-headers-in-websockets-client-api
      if request.headers['HTTP_SEC_WEBSOCKET_PROTOCOL']&.split(',')&.last&.strip&.start_with?('Bearer%20')
        # Parase token from request headers
        token = request.headers['HTTP_SEC_WEBSOCKET_PROTOCOL'].split(',').last.strip.gsub('Bearer%20', '')

        # Check for a token
        doorkeeper_token = Doorkeeper::AccessToken.by_token(token)

        # Check if the token is acceptable
        if doorkeeper_token&.acceptable?(:write)
          user = User.find(doorkeeper_token.resource_owner_id)
          return user unless user.suspended?
        end
      end

      reject_unauthorized_connection
    end
  end
end
