# frozen_string_literal: true

# app/models/Integration/fieldpulse/v1/users.rb
module Integration
  module Fieldpulse
    module V1
      module Users
        # call FieldPulse API to update ClientApiIntegration.users
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).refresh_users
        def refresh_users
          return unless valid_credentials?

          client_api_integration_users.update(data: @fp_client.users, updated_at: Time.current)
        end

        def users_last_updated
          client_api_integration_users_data.present? ? client_api_integration_users.updated_at : nil
        end

        # return a specific user's data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).user()
        #   (req) fp_user_id: (Integer)
        #   (opt) raw:        (Boolean / default: false)
        def user(fp_user_id, args = {})
          return [] if fp_user_id.to_i.zero?

          if (user = client_api_integration_users_data.find { |t| t['id'] == fp_user_id })

            if args.dig(:raw).to_bool
              user.deep_symbolize_keys
            else
              {
                id:    user.dig('id').to_i,
                name:  Friendly.new.fullname(user.dig('first_name')&.to_s, user.dig('last_name')&.to_s),
                phone: user.dig('phone').to_s,
                email: user.dig('email').to_s
              }
            end
          elsif args.dig(:raw).to_bool
            {}
          else
            {
              id:    0,
              name:  '',
              phone: '',
              email: ''
            }
          end
        end

        # return all users data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).users()
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def users(args = {})
          response = client_api_integration_users_data

          if args.dig(:for_select).to_bool
            response.map { |t| [Friendly.new.fullname(t.dig('first_name')&.to_s, t.dig('last_name')&.to_s), t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), name: Friendly.new.fullname(t.dig('first_name')&.to_s, t.dig('last_name')&.to_s), phone: t.dig('phone'), email: t.dig('email') } }&.sort_by { |t| t[:name] }
          end
        end

        private

        def client_api_integration_users
          @client_api_integration_users ||= @client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: 'users')
        end

        def client_api_integration_users_data
          refresh_users if client_api_integration_users.updated_at < 7.days.ago || client_api_integration_users.data.blank?

          client_api_integration_users.data.presence || []
        end
      end
    end
  end
end
