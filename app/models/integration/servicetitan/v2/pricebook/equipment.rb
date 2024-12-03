# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/pricebook/equipment.rb
module Integration
  module Servicetitan
    module V2
      module Pricebook
        module Equipment
          # call ServiceTitan API to update ClientApiIntegration.pricebook_equipment
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_pricebook_equipment
          def refresh_pricebook_equipment
            return unless valid_credentials?

            client_api_integration_pricebook_equipment.update(data: @st_client.pb_equipment, updated_at: Time.current)
          end

          def pricebook_equipment_last_updated
            client_api_integration_pricebook_equipment_data.present? ? client_api_integration_pricebook_equipment.updated_at : nil
          end

          # return all pricebook_equipment data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).pricebook_equipment
          #   (opt) raw: (Boolean / default: false)
          def pricebook_equipment(args = {})
            if args.dig(:raw)
              client_api_integration_pricebook_equipment_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_pricebook_equipment_data.map(&:deep_symbolize_keys)&.map { |c| [c[:name], c[:id]] } || []
            end
          end

          private

          def client_api_integration_pricebook_equipment
            @client_api_integration_pricebook_equipment ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'pricebook_equipment')
          end

          def client_api_integration_pricebook_equipment_data
            refresh_pricebook_equipment if client_api_integration_pricebook_equipment.updated_at < 7.days.ago || client_api_integration_pricebook_equipment.data.blank?

            client_api_integration_pricebook_equipment.data.presence || []
          end
        end
      end
    end
  end
end
