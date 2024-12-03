# frozen_string_literal: true

# app/lib/integrations/field_pulse/v1/users.rb
module Integrations
  module FieldPulse
    module V1
      module Users
        # call FieldPulse API for users
        # fp_client.users
        def users
          reset_attributes
          @result = {}
          users   = []
          page    = 1

          loop do
            params = {
              limit: 100,
              page:
            }

            fieldpulse_request(
              body:                  nil,
              error_message_prepend: 'Integrations::FieldPulse::V1::Users.users',
              method:                'get',
              params:,
              default_result:        @result,
              url:                   'users'
            )

            users += @result.dig(:response) || []
            break if users.length >= @result.dig(:total_results).to_i || @result.dig(:error).to_bool

            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = users.compact_blank
        end
        # example fieldpulse_request result:
        # {
        #   error:            false,
        #   total_results:    2,
        #   response:         [
        #     { id: 190917, first_name: 'Kevin', last_name: 'Neubert', email: 'kevin@chiirp.com', phone: '8023455136', notes: 'The founding user', is_active: true, role: 1 },
        #     { id: 190919, first_name: 'Taylor', last_name: 'Roberts', email: 'taylor@chiirp.com', phone: '', notes: '', is_active: true, role: 4 }
        #   ]
        # }
      end
    end
  end
end
