# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/users.rb
module Integrations
  module SuccessWare
    module V202311
      module Users
        # call Successware API for a user
        # sw_client.user()
        #   (req) successware_user_id: (String)
        def user(successware_user_id = nil)
          reset_attributes
          @result = {}

          if successware_user_id.blank?
            @message = 'Successware user ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                fetchEmployees(inactive: false, employeeCode: #{successware_user_id}) {
                  id
                  employeeCode
                  firstName
                  lastName
                  isTechnician
                  isSalesperson
                  isSubcontracted
                  employeeType
                  email
                  phone
                  cellPhone
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Users.user',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result  = (@result.is_a?(Hash) && @result.dig(:data, :fetchEmployees)&.first) || {}
          @success = @result.present?

          @result
        end

        # call successware API for users
        # sw_client.users
        def users
          reset_attributes
          @result = []

          body = {
            query: <<-GRAPHQL.squish
              query {
                fetchEmployees(inactive: false) {
                  id
                  employeeCode
                  firstName
                  lastName
                  isTechnician
                  isSalesperson
                  isSubcontracted
                  employeeType
                  email
                  phone
                  cellPhone
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::Users.users',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result  = (@result.is_a?(Hash) && @result.dig(:data, :fetchEmployees)) || []
          @success = @result.present?

          @result
        end
      end
    end
  end
end
