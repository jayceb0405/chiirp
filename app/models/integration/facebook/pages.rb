# frozen_string_literal: true

# app/models/Integration/facebook/pages.rb
module Integration
  module Facebook
    module Pages
      PAGE_PERMISSIONS_LEADS     = %w[leadgen].freeze
      PAGE_PERMISSIONS_MESSENGER = %w[messages messaging_postbacks].freeze

      # subscribe Facebook Page to Webhooks
      # fb_model.page_subscribe()
      # Integration::Facebook::Base.new(user_api_integration).page_subscribe()
      #   (req) page_id:     (String)
      #   (req) permissions: (Array) 'leadgen' and/or 'messages' and/or 'messaging_postbacks'
      def page_subscribe(**args)
        reset_attributes

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return @success
        elsif (fb_page = @user_api_integration.pages.find { |p| p['id'] == args[:page_id].to_s }).nil?
          @message = 'Facebook Page not found'
          return @success
        end

        @fb_client.page_subscribe(page_id: fb_page['id'], page_token: fb_page['token'], permissions: args.dig(:permissions))
        update_attributes_from_client

        if success?
          @result   = true
          @success  = true
        else
          @result = false
        end

        @result
      end

      # determine if a Facebook Page is subscribed to Facebook Webhooks
      # fb_model.page_subscribed?()
      # Integration::Facebook::Base.new(user_api_integration).page_subscribed?()
      #   (req) page_id:     (String)
      #   (req) permissions: (Array) 'leadgen' and/or 'messages' and/or 'messaging_postbacks'
      def page_subscribed?(**args)
        reset_attributes
        @result = false

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return @result
        elsif (fb_page = @user_api_integration.pages.find { |p| p['id'] == args[:page_id].to_s }).nil?
          @message = 'Facebook Page not found'
          return @result
        elsif args.dig(:permissions).blank?
          @message = 'Facebook permissions are required'
          return @result
        end

        args[:permissions] = args[:permissions].to_s.split(',').map(&:strip) unless args[:permissions].is_a?(Array)

        @fb_client.subscribed_apps(page_id: fb_page['id'], page_token: fb_page['token'])
        update_attributes_from_client

        if @result.dig(:data).present?
          @result   = (@result[:data].find { |d| d.dig(:name).to_s[0, 6].casecmp?('chiirp') }&.dig(:subscribed_fields).to_a & args[:permissions]).length == args[:permissions].length
          @success  = @result
        else
          @result  = false
          @success = false
          @message = "Unexpected response: #{@result.inspect}"
        end

        @result
      end

      # unsubscribe Facebook Page from Webhooks
      # fb_model.page_unsubscribe()
      # Integration::Facebook::Base.new(user_api_integration).page_unsubscribe()
      #   (req) page_id:     (String)
      def page_unsubscribe(**args)
        reset_attributes

        if args.dig(:page_id).blank?
          @message = 'Facebook Page ID is required'
          return @success
        elsif (fb_page = @user_api_integration.pages.find { |p| p['id'] == args[:page_id].to_s }).nil?
          @message = 'Facebook Page not found'
          return @success
        end

        @fb_client.page_unsubscribe(page_id: fb_page['id'], page_token: fb_page['token'])
        update_attributes_from_client

        if success?
          @result   = true
          @success  = true
        else
          @result = false
        end

        @result
      end

      # validate a Facebook Page token
      # fb_model.valid_page_token?()
      # Integration::Facebook::Base.new.valid_page_token?()
      #   (req) fb_page_id:     (String)
      def valid_page_token?(**args)
        reset_attributes

        if args.dig(:fb_page_id).blank?
          @message = 'Facebook Page ID is required'
          return @success
        elsif (fb_page = @user_api_integration.pages.find { |p| p['id'] == args[:fb_page_id].to_s }).nil?
          @message = 'Facebook Page not found'
          return @success
        end

        @fb_client.page_object(fb_page['token'])
        update_attributes_from_client

        if success?
          @result  = @result.present?
          @success = @result
        else
          @result = false
        end

        @result
      end
    end
  end
end
