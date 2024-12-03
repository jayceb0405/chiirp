# frozen_string_literal: true

# app/lib/integrations/face_book/pages.rb
module Integrations
  module FaceBook
    module Pages
      # subscribe Facebook Page to Webhooks
      # fb_client.page_subscribe()
      # Integrations::FaceBook::Base.new.page_subscribe()
      #   (req) page_id:     (String)
      #   (req) page_token:  (String)
      #   (req) permissions: (Array) 'leadgen' and/or 'messages' and/or 'messaging_postbacks'
      def page_subscribe(**args)
        reset_attributes
        @result = false

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return @result
        elsif args.dig(:page_token).blank?
          @message = 'Facebook Page token is required'
          return @result
        elsif args.dig(:permissions).blank?
          @message = 'Facebook permissions are required.'
          return @result
        end

        args[:permissions] = args[:permissions].is_a?(Array) ? args[:permissions].join(',') : args[:permissions].to_s

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Pages.page_subscribe',
          method:                'post',
          params:                { access_token: args[:page_token], subscribed_fields: args[:permissions] },
          default_result:        false,
          url:                   "#{base_api_url}/#{api_version}/#{args[:page_id]}/subscribed_apps"
        )

        @result
      end
      # example response:
      # {success: true}

      # call Facebook Graph API to determine if a Facebook Page is subscribed to Facebook Webhooks
      # fb_client.subscribed_apps()
      # Integrations::FaceBook::Base.new.subscribed_apps()
      #   (req) page_id:     (String)
      #   (req) page_token:  (String)
      def subscribed_apps(**args)
        reset_attributes
        @result  = {}
        response = []

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return false
        elsif args.dig(:page_token).blank?
          @message = 'Facebook Page token is required'
          return false
        end

        params = {
          access_token: args[:page_token],
          limit:        api_request_limit
        }

        loop do
          facebook_request(
            body:                  nil,
            error_message_prepend: 'Integrations::FaceBook::Pages.subscribed_apps',
            method:                'get',
            params:,
            default_result:        false,
            url:                   "#{base_api_url}/#{api_version}/#{args[:page_id]}/subscribed_apps"
          )

          if success? && @result.is_a?(Hash)
            response += @result.dig(:data) || []
          else
            response = []
            @success = false
            @message = "Unexpected response: #{@result.inspect}"
            break
          end

          break if (params[:after] = @result.dig(:paging, :cursors, :after)).blank?
        end

        @result[:data] = response

        @result
      end
      # example response:
      # {
      #   data: [
      #     {
      #       category:          'Business',
      #       link:              'https://app.chiirp.com/',
      #       name:              'Chiirp',
      #       id:                '1899169686842644',
      #       subscribed_fields: %w[leadgen messages messaging_postbacks]
      #     }
      #   ]
      # }

      # unsubscribe Facebook Page from Messenger Webhooks
      # fb_client.page_unsubscribe()
      # Integrations::FaceBook::Base.new.page_unsubscribe()
      #   (req) page_id:     (String)
      #   (req) page_token:  (String)
      def page_unsubscribe(**args)
        reset_attributes
        @result = false

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return @result
        elsif args.dig(:page_token).blank?
          @message = 'Facebook Page token is required'
          return @result
        end

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Pages.page_unsubscribe',
          method:                'delete',
          params:                { access_token: args[:page_token].to_s },
          default_result:        false,
          url:                   "#{base_api_url}/#{api_version}/#{args[:page_id]}/subscribed_apps"
        )

        @result
      end
      # example response:
      # {success: true}

      # validate a Facebook Page token
      # fb_client.page_object()
      # Integrations::FaceBook::Base.new.page_object()
      #   (req) page_token:  (String)
      def page_object(page_token = '')
        reset_attributes
        @result = {}

        if page_token.blank?
          @message = 'Facebook Page token is required'
          return @result
        end

        facebook_request(
          body:                  nil,
          error_message_prepend: 'Integrations::FaceBook::Pages.page_object',
          method:                'get',
          params:                { access_token: page_token },
          default_result:        {},
          url:                   "#{base_api_url}/#{api_version}/me"
        )

        @result
      end

      # validate Facebook Page tokens
      # fb_client.valid_page_tokens?()
      # Integrations::FaceBook::Base.new.valid_page_tokens?()
      #   (req) pages: (Array) ie: [{ 'name' => String, 'id' => String, 'token' => String }, ...]
      def valid_page_tokens?(*pages)
        response = false

        pages.map(&:deep_symbolize_keys).each do |page|
          response = page_object(page[:token]).present?
          break unless response
        end

        response
      end
    end
  end
end
