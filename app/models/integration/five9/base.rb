# frozen_string_literal: true

# app/models/integration/five9/base.rb
module Integration
  module Five9
    class Base
      attr_reader :client, :client_api_integration, :error, :message, :result, :success
      alias success? success

      CURRENT_VERSION = '12'

      # client_id = xx
      # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'five9', name: ''); f9_model = Integration::Five9::Base.new(client_api_integration); f9_model.call(:valid_credentials?); f9_client = Integrations::FiveNine::Base.new(client_api_integration.credentials)

      # f9_model = Integration::Five9::V12::Base.new()
      #   (req) client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration = nil)
        reset_attributes

        self.client_api_integration = client_api_integration
      end

      def call(method, *args)
        reset_attributes

        f9_model = "Integration::Five9::V#{@client_api_integration.credentials&.dig('version').presence || CURRENT_VERSION}::Base".constantize.new(@client_api_integration)

        if f9_model.respond_to?(method)
          if args.present?
            f9_model.send(method, args)
          else
            f9_model.send(method)
          end

          update_attributes_from_model(f9_model)
        end

        @result
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new(target: 'five9', name: '')
                                  end

        @client    = @client_api_integration.client
        @f9_client = "Integrations::FiveNine::V#{@client_api_integration.credentials&.dig('version').presence || CURRENT_VERSION}::Base".constantize.new(@client_api_integration.credentials)
      end

      def messaging_url
        'https://app.ps.five9.com/sms-service/bandwidth'
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
        @error   = @f9_client.error
        @message = @f9_client.message
        @result  = @f9_client.result
        @success = @f9_client.success?
      end

      def update_attributes_from_model(f9_model)
        @error   = f9_model.error
        @message = f9_model.message
        @result  = f9_model.result
        @success = f9_model.success?
      end
    end
  end
end
