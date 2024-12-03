# frozen_string_literal: true

# app/models/Integration/fieldpulse/v1/lead_sources.rb
module Integration
  module Fieldpulse
    module V1
      module LeadSources
        # call FieldPulse API to update ClientApiIntegration.lead_sources
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).refresh_lead_sources
        def refresh_lead_sources
          return unless valid_credentials?

          client_api_integration_lead_sources.update(data: @fp_client.lead_sources, updated_at: Time.current)
        end

        def lead_sources_last_updated
          client_api_integration_lead_sources_data.present? ? client_api_integration_lead_sources.updated_at : nil
        end

        # return a specific lead_source's data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).lead_source()
        #   (req) fp_lead_source_id: (Integer)
        #   (opt) raw:        (Boolean / default: false)
        def lead_source(fp_lead_source_id, args = {})
          return [] if fp_lead_source_id.to_i.zero?

          if (lead_source = client_api_integration_lead_sources_data.find { |t| t['id'] == fp_lead_source_id })

            if args.dig(:raw).to_bool
              lead_source.deep_symbolize_keys
            else
              {
                id:   lead_source.dig('id').to_i,
                name: lead_source.dig('name')&.to_s
              }
            end
          elsif args.dig(:raw).to_bool
            {}
          else
            {
              id:   0,
              name: ''
            }
          end
        end

        # return all lead_sources data
        # Integration::Fieldpulse::V1::Base.new(client_api_integration).lead_sources()
        #   (opt) for_select:       (Boolean / default: false)
        #   (opt) raw:              (Boolean / default: false)
        def lead_sources(args = {})
          response = client_api_integration_lead_sources_data

          if args.dig(:for_select).to_bool
            response.map { |t| [t.dig('name').to_s, t.dig('id').to_i] }.sort
          elsif args.dig(:raw).to_bool
            response.map(&:deep_symbolize_keys)
          else
            response.map { |t| { id: t.dig('id'), name: t.dig('name') } }&.sort_by { |t| t[:name] }
          end
        end

        private

        def client_api_integration_lead_sources
          @client_api_integration_lead_sources ||= @client.client_api_integrations.find_or_create_by(target: 'fieldpulse', name: 'lead_sources')
        end

        def client_api_integration_lead_sources_data
          refresh_lead_sources if client_api_integration_lead_sources.updated_at < 7.days.ago || client_api_integration_lead_sources.data.blank?

          client_api_integration_lead_sources.data.presence || []
        end
      end
    end
  end
end
