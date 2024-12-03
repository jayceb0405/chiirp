# frozen_string_literal: true

# app/models/Integration/housecallpro/v1/technicians.rb
module Integration
  module Housecallpro
    module V1
      module Technicians
        # call HousecallPro API to update ClientApiIntegration.technicians
        # Integration::Housecallpro::V1::Base.new(client_api_integration).refresh_technicians
        def refresh_technicians
          return unless valid_credentials?

          client_api_integration_technicians.update(data: @hcp_client.technicians, updated_at: Time.current)
        end

        def technicians_last_updated
          client_api_integration_technicians_data.present? ? client_api_integration_technicians.updated_at : nil
        end

        # return a specific technician's data
        # Integration::Housecallpro::V1::Base.new(client_api_integration).technician()
        #   (req) hcp_technician_id: (Integer)
        #   (opt) raw:               (Boolean / default: false)
        def technician(hcp_technician_id, args = {})
          return [] if hcp_technician_id.to_s.blank?

          if (technician = client_api_integration_technicians_data.find { |t| t['id'] == hcp_technician_id })

            if args.dig(:raw).to_bool
              technician.deep_symbolize_keys
            else
              {
                id:        technician.dig('id').to_i,
                firstname: technician.dig('first_name').to_s,
                lastname:  technician.dig('last_name').to_s,
                phone:     technician.dig('mobile_number').to_s,
                email:     technician.dig('email').to_s
              }
            end
          elsif args.dig(:raw).to_bool
            {}
          else
            {
              id:        0,
              firstname: '',
              lastname:  '',
              phone:     '',
              email:     ''
            }
          end
        end

        # return all technicians data
        # Integration::Housecallpro::V1::Base.new(client_api_integration).technicians()
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def technicians(args = {})
          response = client_api_integration_technicians_data

          if args.dig(:for_select).to_bool
            response.map { |t| [Friendly.new.fullname(t.dig('first_name').to_s, t.dig('last_name').to_s), t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), firstname: t.dig('first_name'), lastname: t.dig('last_name'), phone: t.dig('mobile_number'), email: t.dig('email') } }&.sort_by { |t| t[:lastname] + t[:firstname] }
          end
        end

        private

        def client_api_integration_technicians
          @client_api_integration_technicians ||= @client.client_api_integrations.find_or_create_by(target: 'housecallpro', name: 'technicians')
        end

        def client_api_integration_technicians_data
          refresh_technicians if client_api_integration_technicians.updated_at < 7.days.ago || client_api_integration_technicians.data.blank?

          client_api_integration_technicians.data.presence || []
        end
      end
    end
  end
end
