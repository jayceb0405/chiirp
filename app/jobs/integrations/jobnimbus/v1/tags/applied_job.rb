# frozen_string_literal: true

# app/jobs/integrations/jobnimbus/v1/tags/applied_job.rb
module Integrations
  module Jobnimbus
    module V1
      module Tags
        class AppliedJob < ApplicationJob
          # description of this job
          # Integrations::Jobnimbus::V1::Tags::AppliedJob.perform_now()
          # Integrations::Jobnimbus::V1::Tags::AppliedJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobnimbus::V1::Tags::AppliedJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobnimbus_tag_applied').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:     (Integer)
          #   (req) contact_id:    (Integer)
          #   (req) contacttag_id: (Integer)
          def perform(**args)
            super

            return false unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? && Integer(args.dig(:contacttag_id), exception: false).present? &&
                                (contact = Contact.find_by(client_id: args[:client_id].to_i, id: args[:contact_id].to_i)) &&
                                (contacttag = contact.contacttags.find_by(id: args[:contacttag_id].to_i)) &&
                                contact.ext_references.find_by(target: 'jobnimbus').blank? &&
                                (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'jobnimbus', name: '')) &&
                                client_api_integration.push_contacts_tag_id == contacttag.tag_id

            contact_hash          = contact.attributes.deep_symbolize_keys
            contact_hash[:tags]   = contact.tags.map(&:name)
            contact_hash[:phones] = {}

            contact.contact_phones.find_each do |contact_phone|
              contact_hash[:phones][contact_phone.phone] = contact_phone.label
            end

            result = Integrations::JobNimbus::V1::Base.new(client_api_integration.api_key).push_contact_to_jobnimbus(contact: contact_hash)

            return false if result&.dig(:jnid).to_s.blank?

            contact_ext_reference = contact.ext_references.find_or_initialize_by(target: 'jobnimbus')
            contact_ext_reference.update(ext_id: result.dig(:jnid).to_s)
          end
        end
      end
    end
  end
end
