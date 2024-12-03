# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/lead_sources.rb
module Integrations
  module SuccessWare
    module V202311
      module LeadSources
        # call Successware API for leadSourceTypes
        # sw_client.lead_source_types()
        #   (opt) active_only:           (Boolean)
        #   (opt) lead_source_type_code: (String)
        def lead_source_types(args = {})
          reset_attributes
          @result = []

          body = {
            query: <<-GRAPHQL.squish
              query {
                queryLeadSourceTypes (leadSourceTypeCode: "#{args.dig(:lead_source_type_code)}", inactive: #{args.dig(:active_only).nil? ? false : !args.dig(:active_only).to_bool}) {
                  leadSourceTypes {
                    id
                    code
                    isActive
                    leadSource {
                      id
                      code
                      type
                      dnis
                      description
                      isActive
                      legacyLeadSourceId
                      legacyLeadSourceTypeId
                    }
                    legacyLeadSourceTypeId
                  }
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::LeadSources.lead_source_types',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = ((@result.is_a?(Hash) && @result.dig(:data, :queryLeadSourceTypes, :leadSourceTypes)) || []).compact_blank
        end
        # sample result
        # [
        #   {
        #     :id=>"1716000003",
        #     :code=>"Direct Mail",
        #     :isActive=>true,
        #     :leadSource=>[
        #       {
        #         :id=>"1716000149",
        #         :code=>"310/11",
        #         :type=>"Direct Mail",
        #         :dnis=>"",
        #         :description=>"Fayette Directory 07 Electric",
        #         :isActive=>false,
        #         :legacyLeadSourceId=>"",
        #         :legacyLeadSourceTypeId=>"3"
        #       },
        #       ...
        #     ],
        #     ...
        #   }
        # ]

        # call Successware API for leadSources
        # sw_client.lead_sources()
        #   (opt) active_only:      (Boolean)
        #   (opt) dnis:             (String)
        #   (opt) lead_source_code: (String)
        def lead_sources(args = {})
          reset_attributes
          @result = []

          body = {
            query: <<-GRAPHQL.squish
              query {
                queryLeadSources (leadSourceCode: "#{args.dig(:lead_source_code)}", inactive: #{args.dig(:active_only).nil? ? false : !args.dig(:active_only).to_bool}, dnis: "#{args.dig(:dnis)}") {
                  leadSources {
                    id
                    code
                    type
                    dnis
                    description
                    isActive
                    legacyLeadSourceId
                    legacyLeadSourceTypeId
                  }
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::LeadSources.lead_sources',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = ((@result.is_a?(Hash) && @result.dig(:data, :queryLeadSources, :leadSources)) || []).compact_blank
        end
        # sample result
        # [
        #   {
        #     :id=>"1716000308",
        #     :code=>"CTV",
        #     :type=>"Television",
        #     :dnis=>"",
        #     :description=>"CTV",
        #     :isActive=>true,
        #     :legacyLeadSourceId=>"",
        #     :legacyLeadSourceTypeId=>"19"
        #   },
        #   ...
        # ]
      end
    end
  end
end
