# frozen_string_literal: true

# app/jobs/contacts/groups/remove_job.rb
module Contacts
  module Groups
    class RemoveJob < ApplicationJob
      # remove a Contact from a Group
      # Contacts::Groups::RemoveJob.perform_now()
      # Contacts::Groups::RemoveJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Groups::RemoveJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'remove_group').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id: (Integer
      #   (req) group_id:   (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return nil unless args.dig(:group_id).to_i >= 0
        return nil if args[:group_id].to_i.positive? && contact.group_id != args[:group_id].to_i

        contact.update(group_id: 0)
      end
    end
  end
end
