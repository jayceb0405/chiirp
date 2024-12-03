# frozen_string_literal: true

# app/jobs/contacts/tags/remove_job.rb
module Contacts
  module Tags
    class RemoveJob < ApplicationJob
      # remove a Tag from a Contact
      # Contacts::Tags::RemoveJob.perform_now()
      # Contacts::Tags::RemoveJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Tags::RemoveJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'remove_tag').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id: (Integer
      #   (req) tag_id:     (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:tag_id).to_i.positive?
        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?

        contact.contacttags.where(tag_id: args[:tag_id].to_i).destroy_all
      end
    end
  end
end
