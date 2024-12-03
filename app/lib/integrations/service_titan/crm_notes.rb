# frozen_string_literal: true

# app/lib/integrations/service_titan/crm_notes.rb
module Integrations
  module ServiceTitan
    module CrmNotes
      # Create a new Note on a ServiceTitan Customer
      # st_client.new_note()
      #   (req) st_customer_id: (Integer)
      #   (req) content:        (String)
      def new_note(st_customer_id:, content:)
        reset_attributes
        @result = false

        if st_customer_id.to_i.zero? || content.to_s.empty?
          @message = 'ServiceTitan Customer ID is required.'
          return @result
        end

        self.servicetitan_request(
          body:                  {
            text:           content.to_s,
            pinToTop:       false,
            addToLocations: false
          },
          error_message_prepend: 'Integrations::ServiceTitan::CrmNotes.new_note',
          method:                'post',
          params:                nil,
          default_result:        @result,
          url:                   "#{base_url}/#{api_method_crm}/#{api_version}/tenant/#{self.tenant_id}/customers/#{st_customer_id}/notes"
        ).present?
      end
    end
  end
end
