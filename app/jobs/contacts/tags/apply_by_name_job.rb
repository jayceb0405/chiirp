# frozen_string_literal: true

# app/jobs/contacts/tags/apply_by_name_job.rb
module Contacts
  module Tags
    class ApplyByNameJob < ApplicationJob
      # apply a Tag to a Contact by Tag name
      # Contacts::Tags::ApplyByNameJob.perform_now()
      # Contacts::Tags::ApplyByNameJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Tags::ApplyByNameJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'apply_tag_by_name').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id: (Integer
      #   (req) tag_name:   (Integer)
      def perform(**args)
        super

        return nil if args.dig(:tag_name).to_s.blank?
        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return nil unless (tag = contact.client.tags.find_or_create_by(name: args[:tag_name]))

        Contacts::Tags::ApplyJob.perform_now(
          contact_id: contact.id,
          tag_id:     tag.id
        )
      end
    end
  end
end
