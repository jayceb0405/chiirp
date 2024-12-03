# frozen_string_literal: true

# app/jobs/contacts/groups/add_job.rb
module Contacts
  module Groups
    class AddJob < ApplicationJob
      # add a Contact to a Group
      # Contacts::Groups::AddJob.perform_now()
      # Contacts::Groups::AddJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Groups::AddJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'add_group').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id: (Integer
      #   (req) group_id:   (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return nil unless args.dig(:group_id).to_i.positive? && (group = Group.find_by(id: args[:group_id].to_i, client_id: contact.client_id))

        contact.update(group_id: group.id)
      end
    end
  end
end
