# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/technicians.rb
module Integration
  module Servicetitan
    module V2
      module Technicians
        # call ServiceTitan API to update ClientApiIntegration.technicians
        # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_technicians
        def refresh_technicians
          return unless valid_credentials?

          client_api_integration_technicians.update(data: @st_client.technicians, updated_at: Time.current)
        end

        def technicians_last_updated
          client_api_integration_technicians_data.present? ? client_api_integration_technicians.updated_at : nil
        end

        # return a specific technician's data
        # Integration::Servicetitan::V2::Base.new(client_api_integration).technician()
        #   (req) st_technician_id: (Integer)
        #   (opt) raw:              (Boolean / default: false)
        def technician(st_technician_id, args = {})
          return [] if st_technician_id.to_i.zero?

          if (technician = client_api_integration_technicians_data.find { |t| t['id'] == st_technician_id })

            if args.dig(:raw).to_bool
              technician.deep_symbolize_keys
            else
              {
                id:    technician.dig('id').to_i,
                name:  technician.dig('name')&.to_s,
                phone: technician.dig('phoneNumber').to_s,
                email: technician.dig('email').to_s
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

        # return all technicians data
        # Integration::Servicetitan::V2::Base.new(client_api_integration).technicians()
        #   (opt) business_unit_id: (Integer / default: nil)
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def technicians(args = {})
          response = if args.dig(:business_unit_id).to_i.positive?
                       client_api_integration_technicians_data.map { |t| t if t.dig('businessUnitId').to_i == args[:business_unit_id].to_i }.compact_blank
                     else
                       client_api_integration_technicians_data
                     end

          if args.dig(:for_select).to_bool
            response.map { |t| [t.dig('name').to_s, t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), name: t.dig('name'), phone: t.dig('phoneNumber'), email: t.dig('email') } }&.sort_by { |t| t[:name] }
          end
        end

        private

        def client_api_integration_technicians
          @client_api_integration_technicians ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'technicians')
        end

        def client_api_integration_technicians_data
          refresh_technicians if client_api_integration_technicians.updated_at < 7.days.ago || client_api_integration_technicians.data.blank?

          client_api_integration_technicians.data.presence || []
        end
      end
    end
  end
end
