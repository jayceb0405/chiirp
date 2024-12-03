# frozen_string_literal: true

# app/jobs/contacts/tags/apply_job.rb
module Contacts
  module Tags
    class ApplyJob < ApplicationJob
      # apply a Tag to a Contact
      # Contacts::Tags::ApplyJob.perform_now()
      # Contacts::Tags::ApplyJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Tags::ApplyJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'apply_tag').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id: (Integer
      #   (req) tag_id:     (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return nil unless args.dig(:tag_id).to_i.positive? && (tag = contact.client.tags.find_by(id: args[:tag_id].to_i))

        if (contacttag = contact.contacttags.find_by(tag_id: tag.id))
          contacttag.update(updated_at: Time.current)
          contacttag
        else
          contact.contacttags.create(tag_id: tag.id)
        end
      end
    end
  end
end
