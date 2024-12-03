# frozen_string_literal: true

# app/jobs/contacts/stages/remove_job.rb
module Contacts
  module Stages
    class RemoveJob < ApplicationJob
      # remove a Contact from a Stage
      # Contacts::Stages::RemoveJob.perform_now()
      # Contacts::Stages::RemoveJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Stages::RemoveJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'remove_stage').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id: (Integer
      #   (req) stage_id:   (Integer)
      def perform(**args)
        super

        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return nil unless args.dig(:stage_id).to_i >= 0
        return nil if args[:stage_id].to_i.positive? && contact.stage_id != args[:stage_id].to_i

        contact.update(stage_id: 0)
      end
    end
  end
end
