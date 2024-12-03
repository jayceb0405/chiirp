# frozen_string_literal: true

# app/lib/integrations/ggl/business_messages/brands.rb
module Integrations
  module Ggl
    module BusinessMessages
      # Google Brands methods called by Google Messages class
      # ggl_client = Integrations::Ggl::Base.new(token, I18n.t('tenant.id'))
      module Brands
        def business_messages_brand(brand_id)
          reset_attributes
          @result = []

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.Brand',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/#{brand_id}"
          )

          @result
        end

        # A brand (business, organization, or group) that is represented by an agent
        # ggl_client.brands
        def business_messages_brands
          reset_attributes
          @result = []

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.Brands',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/brands"
          )

          @result
        end

        # create a Google Business Messages Brand
        # ggl_client.business_messages_create_brand(name)
        # (req) name: (String)
        def business_messages_create_brand(name)
          reset_attributes
          @result = {}

          if name.blank?
            @message = 'Brand name required.'
            return @result
          end

          body = { displayName: name }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.BrandCreate',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/brands"
          )

          @result
        end
        # sample result
        # { name: "brands/2f35dc4e-1790-4859-82b0-bc2a87c2d292", displayName: "Harry" }

        # delete a Brand (deletes Agents & Locations if they exist)
        # ggl_client.business_messages_delete_brand(brand_id)
        # (req) brand_id: (String)
        def business_messages_delete_brand(brand_id)
          reset_attributes
          @result = {}

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          end

          self.google_request(
            body:                  nil,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.BrandDelete',
            method:                'delete',
            params:                { force: true },
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/#{brand_id}"
          )

          @result
        end

        def business_messages_update_brand(brand_id, name)
          reset_attributes
          @result = {}

          if brand_id.blank?
            @message = 'Brand ID required.'
            return @result
          elsif name.blank?
            @message = 'New name required.'
            return @result
          end

          body = { displayName: name }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.BrandUpdate',
            method:                'patch',
            params:                nil,
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/#{brand_id}"
          )

          @result
        end

        def update_webhook_url
          reset_attributes
          @result = {}

          body = {
            productCapabilities: [
              {
                product:                    'BUSINESS_MESSAGES',
                businessMessagesCapability: {
                  webhookUrl: self.business_messages_webhook_url
                }
              }
            ]
          }

          self.google_request(
            body:,
            error_message_prepend: 'Integrations::Ggl::BusinessMessages::Brands.UpdateWebhookUrl',
            method:                'patch',
            params:                { updateMask: 'productCapabilities' },
            default_result:        @result,
            url:                   "#{brands_base_url}/#{brands_base_version}/partners/#{business_messages_partner_id}"
          )

          @result
        end

        private

        def brands_base_url
          'https://businesscommunications.googleapis.com'
        end

        def brands_base_version
          'v1'
        end
      end
    end
  end
end
