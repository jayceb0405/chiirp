# frozen_string_literal: true

# app/models/Integration/housecallpro/v1/tags.rb
module Integration
  module Housecallpro
    module V1
      module Tags
        def apply_tags_from_webhook(contact, tag_names)
          tag_names.each do |tag_name|
            unless Tag.find_by(id: contact.contacttags.pluck(:tag_id), name: tag_name)
              Contacts::Tags::ApplyByNameJob.perform_later(
                contact_id: contact.id,
                tag_name:   tag_name,
                user_id:    contact.user_id,
              )
            end
          end
        end

        # a Tag was applied to Contact / if Tag is defined to send Contact to Housecall Pro then send it
        # hcp_model.tag_applied()
        #   (req) contacttag: (Contacttag)
        def tag_applied(contacttag)
          return unless contacttag.is_a?(Contacttag) && self.valid_credentials? && @client_api_integration.push_leads_tag_id == contacttag.tag_id

          contact_hash              = contacttag.contact.attributes.deep_symbolize_keys
          contact_hash[:tags]       = contacttag.contact.tags.map(&:name)
          contact_hash[:phone]      = contacttag.contact.primary_phone&.phone.to_s
          contact_hash[:ext_ref_id] = contacttag.contact.ext_references.find_by(target: 'housecallpro')&.ext_id.to_s

          result = @hcp_client.push_contact_to_housecallpro(contact_hash)

          return if result.blank?

          contact_ext_reference = contacttag.contact.ext_references.find_or_initialize_by(target: 'housecallpro')
          contact_ext_reference.update(ext_id: result)
        end
      end
    end
  end
end
