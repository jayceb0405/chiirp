# frozen_string_literal: true

# app/models/Integration/facebook/base.rb
module Integration
  module Facebook
    class Base
      attr_reader :error, :message, :result, :success
      alias success? success

      include Facebook::Leads
      include Facebook::Pages

      # user_id = xx
      # user_api_integration = UserApiIntegration.find_by(user_id: user_id, target: 'facebook', name: ''); fb_model = Integration::Facebook::Base.new(user_api_integration); fb_model.valid_credentials?; fb_client = Integrations::FaceBook::Base.new(fb_user_id: user_api_integration.data.dig('users')&.first&.dig('id'), token: user_api_integration.data.dig('users')&.first&.dig('token'))

      # fb_model = Integration::Facebook::Base.new(user_api_integration)
      #   (req) user_api_integration: (UserApiIntegration)
      #   (opt) fb_user_id:           (String)
      def initialize(user_api_integration = nil, **args)
        reset_attributes
        self.user_api_integration = user_api_integration
        Rails.logger.info "@user_api_integration: #{@user_api_integration.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "@user_api_integration.user: #{@user_api_integration.user.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        Rails.logger.info "@user_api_integration.user.client: #{@user_api_integration.user.client.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        @client                   = @user_api_integration.user.client
        @fb_user_id               = args.dig(:fb_user_id) || @user_api_integration.data.dig('users')&.first&.dig('id')
        @fb_user                  = @user_api_integration.data.dig('users')&.find { |u| u['id'] == @fb_user_id } || {}
        @user                     = @user_api_integration.user
        @fb_client                = Integrations::FaceBook::Base.new(fb_user_id: @fb_user.dig('id'), token: @fb_user.dig('token'))
      end

      # validate a User token
      # fb_model.valid_credentials?
      # Integration::Facebook::Base.new(user_api_integration).valid_credentials?()
      #   (opt) fb_user_id: (String)
      def valid_credentials?(**args)
        if args.dig(:fb_user_id).present? && args[:fb_user_id].to_s != @fb_user_id.to_s && (fb_user = @user_api_integration.data.dig('users').find { |u| u['id'] == args[:fb_user_id].to_s })
          fb_client = Integrations::FaceBook::Base.new(fb_user_id: fb_user.dig('id'), token: fb_user.dig('token'))
          fb_client.valid_credentials?
        else
          @fb_client.valid_credentials?
        end
      end

      private

      def put_attributes
        Rails.logger.info "@success: #{@success.inspect} / @error: #{@error.inspect} / @message: #{@message.inspect} / @result: #{@result} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
      end

      def reset_attributes
        @error   = 0
        @message = ''
        @result  = nil
        @success = false
      end

      def update_attributes_from_client
        @error   = @fb_client.error
        @message = @fb_client.message
        @result  = @fb_client.result
        @success = @fb_client.success?
      end

      def user_api_integration=(user_api_integration)
        @user_api_integration = case user_api_integration
                                when UserApiIntegration
                                  user_api_integration
                                when Integer
                                  UserApiIntegration.find_by(id: user_api_integration)
                                else
                                  UserApiIntegration.new(target: 'facebook', name: '')
                                end

        @user_api_integration_leads     = nil
        @user_api_integration_messenger = nil
      end

      def user_api_integration_leads
        @user_api_integration_leads ||= @user_api_integration.user.user_api_integrations.find_or_create_by(target: 'facebook', name: 'leads')
      end

      def user_api_integration_messenger
        @user_api_integration_messenger ||= @user_api_integration.user.user_api_integrations.find_or_create_by(target: 'facebook', name: 'messenger')
      end
    end
  end
end
