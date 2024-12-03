# frozen_string_literal: true

# Integrations::ThumbTack::V2::Base.new(cai.credentials)
# app/lib/integrations/thumb_tack/v2/account.rb
module Integrations
  module ThumbTack
    module V2
      module Account
        # call Thumbtack API for client account info
        # tt_client.account
        def account
          reset_attributes
          @result = {}

          thumbtack_request(
            default_result:        @result,
            endpoint:              'get-thumbtack-info',
            error_message_prepend: 'Integrations::ThumbTack::V2::Account.account',
            method:                'get'
          )

          @result
        end

        # return Thumbtack URL used to create connection
        # tt_model.redirect_url
        def redirect_url
          Rails.application.routes.url_helpers.integrations_thumbtack_auth_code_url(host: I18n.with_locale('chiirp') { I18n.t("tenant.#{Rails.env}.app_host") })
        end

        # disconnect Thumbtack account
        # tt_disconnect_account
        def disconnect_account
          reset_attributes
          @result = {}

          params = {
            business_pk: @credentials.dig(:account, 'business_pk')
          }

          thumbtack_request(
            authorization:         Base64.strict_encode64("#{@credentials.dig(:account, 'client_id')}:#{client_secret}"),
            auth_type:             'Basic',
            default_result:        @result,
            endpoint:              'disconnect-partner',
            error_message_prepend: 'Integrations::ThumbTack::V2::Account.disconnect_account',
            method:                'post',
            params:
          )

          @result
        end

        # refresh Thumbtack access_token using refresh_token
        # tt_client.refresh_access_token(refresh_token)
        #   (req) refresh_token: (String)
        def refresh_access_token(refresh_token = '')
          reset_attributes
          @result = {}

          if refresh_token.blank?
            @message = 'Authorization refresh_token is required!'
            return @result
          end

          params = {
            grant_type:    'refresh_token',
            refresh_token:,
            token_type:    'REFRESH'
          }

          thumbtack_request(
            authorization:         Base64.strict_encode64("#{client_id}:#{client_secret}"),
            auth_type:             'Basic',
            default_result:        @result,
            endpoint:              access_token_url,
            error_message_prepend: 'Integrations::ThumbTack::V2::Account.refresh_access_token',
            method:                'post',
            params:
          )

          Rails.logger.info "Integrations::ThumbTack::V2::Base.refresh_access_token: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

          @result
        end

        # request access_token & refresh_token from Thumbtack
        # tt_client.request_access_token(code)
        #   (req) code:   (String)
        #   (opt) scope:  (String)
        def request_access_token(**args)
          reset_attributes
          @result = {}

          if args.dig(:code).blank?
            @message = 'Authorization code is required!'
            return @result
          end

          params = {
            code:         args[:code],
            grant_type:   'authorization_code',
            redirect_uri: redirect_url,
            token_type:   'AUTH_CODE'
          }

          thumbtack_request(
            authorization:         Base64.strict_encode64("#{client_id}:#{client_secret}"),
            auth_type:             'Basic',
            default_result:        @result,
            endpoint:              access_token_url,
            error_message_prepend: 'Integrations::ThumbTack::V2::Account.request_access_token',
            method:                'post',
            params:
          )

          @result
        end
        # example @result:
        # {
        #   access_token:  '1.eyJCdXNpbmVzc1BLIjozODgwMDYwNjczNTExNTA1OTUsIkNsaWVudElEIjoiVEhVTUJUQUNLIElOVEVSTkFMIiwiU2NvcGUiOlsibWVzc2FnZXMiXSwiRXhwaXJlc0F0IjoiMjAyMS0xMC0xNFQwMjo1OToyOS44MjIwMDU2ODhaIiwiU3JjQXV0aENvZGUiOiIwNjcwODgwODI0M2QyOTYxN2E1OTc4ZmZjNmQ4OGRkY2UzYjBjNDQyOThmYzFjMTQ5YWZiZjRjODk5NmZiOTI0MjdhZTQxZTQ2NDliOTM0Y2E0OTU5OTFiNzg1MmI4NTUifQ.qJDfeuYfdFZCSVQmBUgr_kDoZeeEUD4y4oVTVMEc4EQ',
        #   token_type:    'bearer',
        #   expires_in:    3600,
        #   refresh_token: '_s3cnwGAb5VgBt-CmYFSOw'
        # }

        def valid_credentials?
          (@credentials.dig(:access_token).present? || @credentials.dig(:refresh_token).present?) && Time.parse(@credentials.dig(:expires_at)).utc > Time.current.utc
        end

        private

        def access_token_url
          'tokens/access'
        end
      end
    end
  end
end
