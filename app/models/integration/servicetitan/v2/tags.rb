# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/tags.rb
module Integration
  module Servicetitan
    module V2
      module Tags
        # apply ServiceTitan tags to Contact
        # st_model.apply_servicetitan_tags()
        #   (req) contact:           (Contact)
        #   (req) servicetitan_tags: (Array)
        def apply_servicetitan_tags(contact, servicetitan_tags)
          JsonLog.info 'Integration::Servicetitan::V2::Tags.apply_servicetitan_tags', { contact:, servicetitan_tags: }, contact_id: contact&.id
          return unless contact.is_a?(Contact) && servicetitan_tags.is_a?(Array)

          servicetitan_tags.each { |servicetitan_tag| Contacts::Tags::ApplyByNameJob.perform_now(contact_id: contact.id, tag_name: servicetitan_tag.dig(:name)) }
        end

        # a Tag was applied to Contact / push to ServiceTitan if Tag is selected
        # st_model.push_tag_applied()
        #   (req) contact_tag: (Contacttag)
        def push_tag_applied(contact_tag)
          unless contact_tag.is_a?(Contacttag)
            JsonLog.info 'Integration::Servicetitan::V2::Tags.push_tag_applied', { contact_tag: }
            return
          end

          @client_api_integration.push_contacts&.map(&:symbolize_keys)&.each do |push_contact|
            self.push_contact_to_servicetitan(contact: contact_tag.contact, type: push_contact.dig(:type), push_contact:) if push_contact.dig(:tag_id) == contact_tag.tag_id
          end
        end

        # call ServiceTitan API to update ClientApiIntegration.tag_types
        # Integration::Servicetitan::V2::Base.new(client_api_integration).refresh_tag_types
        def refresh_tag_types
          return unless valid_credentials?

          client_api_integration_tag_types.update(data: @st_client.tag_types, updated_at: Time.current)
        end

        # Convert ServiceTitan tag names received in webhooks into ServiceTitan tag ids
        # When tags are received from ServiceTitan in webhooks the "id" received for each tag is the id of the record connecting a tag to a customer, job, etc.
        # st_model.tag_names_to_ids(Array)
        # (opt) tag_names: (Array) of Strings
        def tag_names_to_ids(tag_names = [])
          return [] unless tag_names.present? && self.valid_credentials?

          servicetitan_tags = tag_types
          ext_tag_ids = []

          tag_names.each do |tag_name|
            servicetitan_tag = servicetitan_tags.find { |t| t[0] == tag_name }
            ext_tag_ids << servicetitan_tag[1] if servicetitan_tag.present?
          end

          ext_tag_ids
        end

        # return all tag_types data
        # Integration::Servicetitan::V2::Base.new(client_api_integration).tag_types
        #   (opt) raw: (Boolean / default: false)
        def tag_types(args = {})
          if args.dig(:raw)
            client_api_integration_tag_types_data.map(&:deep_symbolize_keys)
          else
            client_api_integration_tag_types_data.map(&:deep_symbolize_keys)&.map { |t| [t[:name], t[:id]] }&.sort || []
          end
        end

        def tag_types_last_updated
          client_api_integration_tag_types_data.present? ? client_api_integration_tag_types.updated_at : nil
        end

        private

        def client_api_integration_tag_types
          @client_api_integration_tag_types ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'tag_types')
        end

        def client_api_integration_tag_types_data
          refresh_tag_types if client_api_integration_tag_types.updated_at < 7.days.ago || client_api_integration_tag_types.data.blank?

          client_api_integration_tag_types.data.presence || []
        end
      end
    end
  end
end
