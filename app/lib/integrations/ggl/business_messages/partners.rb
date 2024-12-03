# frozen_string_literal: true

# app/lib/integrations/ggl/business_messages/brands.rb
module Integrations
  module Ggl
    module BusinessMessages
      # Google Partner methods called by Google Messages class
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Partners
        def business_messages_partner_info
          reset_attributes
          @result = {}

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.PartnerInfo',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/partners/#{business_messages_partner_id}"
          )

          @result
        end
      end
    end
  end
end
