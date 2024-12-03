# frozen_string_literal: true

# app/lib/fb/users.rb
module Integrations
  module FaceBook
    module Users
      # delete a User connection
      # fb_client.user_delete
      # Integrations::FaceBook::Base.new(token: String, fb_user_id: String).user_delete
      def user_delete
        reset_attributes
        @result = false

        if @token.empty?
          @message = 'Missing required Facebook User token.'
          return @result
        elsif self.user.dig(:id).to_s.blank?
          reset_attributes

          if @error == 400
            @success = true
            @result  = true
          else
            @message = 'Permissions unknown.'
            @result  = false
          end

          return @result
        end

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Users.user_delete',
          method:                'delete',
          params:                { access_token: @token },
          default_result:        @result,
          url:                   "#{self.base_api_url}/#{self.api_version}/#{@fb_user_id}/permissions"
        )

        if success?
          @result   = true
          @success  = true
        else
          @error   = result.status
          @message = ''
        end

        @result
      end

      # get long-lived Facebook page tokens from a long-lived Facebook user token
      # fb_client.user_pages
      # Integrations::FaceBook::Base.new(token: String, fb_user_id: String).user_pages
      def user_pages
        reset_attributes
        response = []

        if @token.empty?
          @message = 'Missing required Facebook User token.'
          return response
        end

        params = {
          access_token: @token,
          limit:        self.api_request_limit
        }

        loop do
          facebook_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FaceBook::Users.user_pages',
            method:                'get',
            params:,
            default_result:        [],
            url:                   "#{self.base_api_url}/#{self.api_version}/#{@fb_user_id}/accounts"
          )

          if self.success? && @result.is_a?(Hash)
            response += @result.dig(:data).map { |page| { id: page[:id], name: page[:name], token: page[:access_token] } }
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end

          break if (params[:after] = @result.dig(:paging, :cursors, :after)).blank?
        end

        @result = response
      end

      # get a Facebook user from a Facebook user token
      # fb_client.user
      # Integrations::FaceBook::Base.new(token: String, fb_user_id: String).user
      def user
        reset_attributes
        @result = { id: '', name: '' }

        if @token.empty?
          @message = 'Missing required Facebook User token.'
          return @result
        end

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Users.user',
          method:                'get',
          params:                { access_token: @token },
          default_result:        { id: '', name: '' },
          url:                   "#{self.base_api_url}/#{self.api_version}/#{@fb_user_id}"
        )

        @result
      end

      # get a Facebook user from a Facebook user token
      # fb_client.user_permissions
      # Integrations::FaceBook::Base.new(token: String, fb_user_id: String).user_permissions
      def user_permissions
        reset_attributes
        response = []

        if @token.empty?
          @message = 'Missing required Facebook User token.'
          return @result = response
        elsif self.user.dig(:id).to_s.blank?
          reset_attributes
          @message = 'Permissions unknown.'
          return @result = response
        end

        params = {
          access_token: @token,
          limit:        self.api_request_limit
        }

        loop do
          facebook_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FaceBook::Users.user_permissions',
            method:                'get',
            params:                { access_token: @token },
            default_result:        [],
            url:                   "#{self.base_api_url}/#{self.api_version}/#{@fb_user_id}/permissions"
          )

          if self.success? && @result.is_a?(Hash)
            response += @result.dig(:data)
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end

          break if (params[:after] = @result.dig(:paging, :cursors, :after)).blank?
        end

        @result = response
      end
    end
  end
end
