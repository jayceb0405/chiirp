# frozen_string_literal: true

# app/lib/integrations/ggl/my_business_account_management/accounts.rb
module Integrations
  module Ggl
    module MyBusinessAccountManagement
      # Google API calls to support Business Profile Accounts
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Accounts
        # get a Google Account
        # ggl_client.my_business_account
        # (req) account_id: (String / ex: 'accounts/106702836638822736000')
        def my_business_account(account_id)
          reset_attributes
          @result = {}

          if account_id.blank?
            @message = 'Account ID is required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::MyBusinessAccountManagement::Accounts.my_business_account',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{my_business_account_management_base_url}/#{my_business_account_management_base_version}/#{account_id}"
          )

          @result
        end

        # get a list of Google Accounts
        # ggl_client.my_business_accounts
        # docs: https://developers.google.com/my-business/reference/accountmanagement/rest/v1/accounts/list
        def my_business_accounts
          reset_attributes
          response = []

          # pageSize: Optional. How many accounts to fetch per page. The default and maximum is 20.
          params = {
            pageSize: 20
          }

          loop do
            self.google_request(
              body:                  nil,
              error_message_prepend: 'Integrations::Ggl::MyBusinessAccountManagement::Accounts.my_business_accounts',
              method:                'get',
              params:                nil,
              default_result:        [],
              url:                   "#{my_business_account_management_base_url}/#{my_business_account_management_base_version}/#{api_method_accounts}"
            )

            if @success && @result.is_a?(Hash)
              response += @result.dig(:accounts) || []
              break if (params[:pageToken] = @result.dig(:nextPageToken)).blank?
            else
              response = []
              break
            end
          end

          @result = response
        end

        private

        def api_method_accounts
          'accounts'
        end
      end
    end
  end
end
