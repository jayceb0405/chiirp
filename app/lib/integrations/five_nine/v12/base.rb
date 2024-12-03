# frozen_string_literal: true

# app/lib/integrations/five_nine/v12/base.rb
module Integrations
  module FiveNine
    module V12
      class Base < Integrations::FiveNine::Base
        include FiveNine::V12::Campaigns
        include FiveNine::V12::Contacts
        include FiveNine::V12::Dispositions
        include FiveNine::V12::Lists
        include FiveNine::V12::Messages

        def valid_credentials?
          @credentials.dig(:username).present? && @credentials.dig(:password).present?
        end

        private

        def api_url
          'https://api.five9.com/wsadmin'
        end

        def api_version
          'v12'
        end

        def credentials
          Base64.strict_encode64("#{@credentials.dig(:username).to_s.strip}:#{@credentials.dig(:password).to_s.strip}")
        end

        def five9_client
          Savon.client(
            wsdl:                    "#{api_url}/#{api_version}/AdminWebService?wsdl&user=#{@credentials.dig(:username).to_s.strip}",
            namespace:               'http://service.admin.ws.five9.com/',
            basic_auth:              [@credentials.dig(:username).to_s.strip, @credentials.dig(:password).to_s.strip],
            log:                     true,
            log_level:               :error,
            env_namespace:           :soapenv,
            namespace_identifier:    :ser,
            ssl_verify_mode:         :none,
            convert_request_keys_to: :lower_camelcase,
            pretty_print_xml:        true
          )
        end
      end
    end
  end
end
