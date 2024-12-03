# frozen_string_literal: true

# Integration::Thumbtack::V2::Base.new(client_api_integration)
# app/models/integration/thumbtack/v2/base.rb
module Integration
  module Thumbtack
    module V2
      class Base < Integration::Thumbtack::Base
        include Integration::Thumbtack::V2::Events

        EVENT_TYPES = [
          %w[Lead lead],
          ['Lead Update', 'lead_update'],
          %w[Message message],
          %w[Review review]
        ].freeze
        LEAD_TYPES = [
          %w[Availability availability],
          %w[Contact contact],
          %w[Estimation estimation],
          %w[Call call],
          %w[Booking booking],
          ['Phone Consultation', 'phone_consultation'],
          ['Instant Book', 'instant_book'],
          %w[Sponsored sponsored],
          ['Instant Consult', 'instant_consult'],
          ['Service Call', 'service_call'],
          %w[Fulfillment fulfillment],
          ['Request A Quote', 'request_a_quote'],
          ['Mismatch Request A Quote', 'mismatch_request_a_quote']
        ].freeze

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'thumbtack', name: ''); tt_model = Integration::Thumbtack::V2::Base.new(client_api_integration); tt_model.valid_credentials?; tt_client = Integrations::ThumbTack::Base.new(client_api_integration.credentials)

        def event_types
          EVENT_TYPES
        end

        def lead_types
          LEAD_TYPES
        end

        # return Thumbtack URL used to create connection
        # tt_model.connect_to_thumbtack_url
        def connect_to_thumbtack_url
          "https://#{Rails.env.development? ? 'staging-partner.' : ''}thumbtack.com/services/partner-connect/?client_id=#{CGI.escape(Rails.application.credentials[:thumbtack][:client_id])}&redirect_uri=#{CGI.escape(@tt_client.redirect_url)}&response_type=code&scope=messages&state=#{CGI.escape(@client_api_integration.auth_code)}"
        end

        def disconnect_account
          reset_attributes

          return false unless valid_credentials? && self.update_account && @tt_client.disconnect_account && @tt_client.success?

          @client_api_integration.credentials = {}
          @client_api_integration.save
          @result = @success = true
        end

        # update ClientApiIntegration.account from Thumbtack client
        # tt_model.update_account
        def update_account
          reset_attributes

          return false unless valid_credentials? && (account = @tt_client.account) && @tt_client.success?

          @client_api_integration.credentials[:account] = account
          @client_api_integration.save

          refresh_client

          @result = @success = true
        end

        # update ClientApiIntegration.credentials from code or refresh_token
        # tt_model.update_credentials()
        #   (opt) code:  (String)
        #   (opt) scope: (String)
        def update_credentials(**args)
          reset_attributes

          if args.dig(:code).present? && args.dig(:scope).present?
            update_credentials_by_code(code: args[:code], scope: args[:scope])
          elsif @client_api_integration.credentials.dig('refresh_token').present?
            update_credentials_by_refresh_token
          end

          refresh_client

          @result = @success = valid_credentials?
        end

        # validate the access_token & refresh if necessary
        # tt_model.valid_credentials?
        def valid_credentials?
          if @tt_client.valid_credentials?
            true
          elsif @client_api_integration.credentials.present?
            update_credentials
          else
            @client_api_integration.update(credentials: {})
            false
          end
        end

        private

        def put_attributes
          Rails.logger.info "@success: #{@success.inspect} / @error: #{@error.inspect} / @message: #{@message.inspect} / @result: #{@result} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
        end

        def update_attributes_from_client
          @error   = @tt_client.error
          @message = @tt_client.message
          @result  = @tt_client.result
          @success = @tt_client.success?
        end

        def update_attributes_from_model(tt_model)
          @error   = tt_model.error
          @message = tt_model.message
          @result  = tt_model.result
          @success = tt_model.success?
        end

        # update ClientApiIntegration.credentials from code
        # tt_model.update_credentials_by_code(code)
        #   (opt) code:  (String)
        #   (opt) scope: (String)
        def update_credentials_by_code(**args)
          @client_api_integration.credentials = @tt_client.request_access_token(code: args.dig(:code))
          update_credentials_expiration_and_version
        end

        # update ClientApiIntegration.credentials from refresh token
        # tt_model.update_credentials_by_refresh_token
        def update_credentials_by_refresh_token
          @client_api_integration.credentials = @tt_client.refresh_access_token(@client_api_integration.credentials['refresh_token'])
          update_credentials_expiration_and_version
        end

        # update ClientApiIntegration.credentials expires_at & version
        # tt_model.update_credentials_expiration_and_version
        def update_credentials_expiration_and_version
          @client_api_integration.credentials['expires_at']    = 50.minutes.from_now
          @client_api_integration.credentials['version']       = CURRENT_VERSION
          @client_api_integration.save

          @tt_client = Integrations::ThumbTack::V2::Base.new(@client_api_integration.credentials)
        end
      end
    end
  end
end
