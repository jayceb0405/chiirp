# frozen_string_literal: true

# app/jobs/contacts/lead_sources/assign_job.rb
module Contacts
  module LeadSources
    class AssignJob < ApplicationJob
      # assign a Lead Source to a Contact
      # Contacts::LeadSources::AssignJob.perform_now()
      # Contacts::LeadSources::AssignJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::LeadSources::AssignJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'assign_lead_source').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id:     (Integer
      #   (req) lead_source_id: (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:lead_source_id).present?
        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return nil unless (args[:lead_source_id].to_i.zero? || (lead_source = Clients::LeadSource.find_by(id: args[:lead_source_id].to_i, client_id: contact.client_id)))

        contact.update(lead_source_id: args[:lead_source_id].to_i.zero? ? nil : lead_source.id)
      end
    end
  end
end
