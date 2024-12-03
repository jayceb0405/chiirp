# frozen_string_literal: true

# app/lib/integrations/field_pulse/v1/lead_sources.rb
module Integrations
  module FieldPulse
    module V1
      module LeadSources
        # call FieldPulse API for lead sources
        # fp_client.lead_sources
        def lead_sources
          reset_attributes
          @result      = {}
          lead_sources = []
          page         = 1

          loop do
            params = {
              limit: 100,
              page:
            }

            fieldpulse_request(
              body:                  nil,
              error_message_prepend: 'Integrations::FieldPulse::V1::LeadSources.lead_sources',
              method:                'get',
              params:,
              default_result:        @result,
              url:                   'lead-source'
            )

            lead_sources += @result.dig(:response) || []
            break if lead_sources.length >= @result.dig(:total_results).to_i || @result.dig(:error).to_bool

            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))
          end

          @result = lead_sources.compact_blank
        end
        # example fieldpulse_request result:
        # {
        #   error:         false,
        #   total_results: 3,
        #   response:      [
        #     { id: 843255, company_id: 114785, author_id: 190917, name: 'Amazon', created_at: '2024-09-12 19:31:14', updated_at: '2024-09-12 19:31:14', deleted_at: null },
        #     { id: 843248, company_id: 114785, author_id: 190917, name: 'Purchased Leads', created_at: '2024-09-12 19:31:14', updated_at: '2024-09-12 19:31:14', deleted_at: null },
        #     { id: 843249, company_id: 114785, author_id: 190917, name: "Angie's List", created_at: '2024-09-12 19:31:14', updated_at: '2024-09-12 19:31:14', deleted_at: null }
        #   ]
        # }
      end
    end
  end
end
