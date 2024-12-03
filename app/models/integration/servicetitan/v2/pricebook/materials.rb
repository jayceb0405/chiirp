# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/pricebook/materials.rb
module Integration
  module Servicetitan
    module V2
      module Pricebook
        module Materials
          # call ServiceTitan API to update ClientApiIntegration.pricebook_materials
          # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_pricebook_materials
          def refresh_pricebook_materials
            return unless valid_credentials?

            client_api_integration_pricebook_materials.update(data: @st_client.pb_materials, updated_at: Time.current)
          end

          def pricebook_materials_last_updated
            client_api_integration_pricebook_materials_data.present? ? client_api_integration_pricebook_materials.updated_at : nil
          end

          # return all pricebook_materials data
          # Integration::Servicetitan::V2::Base.new(client_api_integration).pricebook_materials
          #   (opt) raw: (Boolean / default: false)
          def pricebook_materials(args = {})
            if args.dig(:raw)
              client_api_integration_pricebook_materials_data.map(&:deep_symbolize_keys)
            else
              client_api_integration_pricebook_materials_data.map(&:deep_symbolize_keys)&.map { |c| [c[:name], c[:id]] } || []
            end
          end

          private

          def client_api_integration_pricebook_materials
            @client_api_integration_pricebook_materials ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'pricebook_materials')
          end

          def client_api_integration_pricebook_materials_data
            refresh_pricebook_materials if client_api_integration_pricebook_materials.updated_at < 7.days.ago || client_api_integration_pricebook_materials.data.blank?

            client_api_integration_pricebook_materials.data.presence || []
          end
        end
      end
    end
  end
end
