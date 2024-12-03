# frozen_string_literal: true

# app/jobs/contacts/stages/add_job.rb
module Contacts
  module Stages
    class AddJob < ApplicationJob
      # add a Contact to a Stage
      # Contacts::Stages::AddJob.perform_now()
      # Contacts::Stages::AddJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Stages::AddJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'add_stage').to_s
      end

      # perform the ActiveJob
      #   (req) client_id:     (Integer)
      #   (req) contact_id:    (Integer
      #   (req) stage_id:      (Integer)
      def perform(**args)
        super

        # TODO: 2027-10-29 uncomment and delete subsequent return nil when DelayedJob.where(process: 'add_stage', created_at: ..'2024-10-29'.to_date.end_of_day) == 0
        # return nil unless args.dig(:client_id).to_i.positive? && (client = Client.find_by(id: args[:client_id].to_i)).present? && client.active? &&
        #                   args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(client_id: client.id, id: args[:contact_id].to_i)).present? &&
        #                   contact.stage_id != args.dig(:stage_id).to_i &&
        #                   args.dig(:stage_id).to_i.positive? && (stage = Stage.for_client(client.id).find_by(id: args[:stage_id].to_i))
        return nil unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active? &&
                          contact.stage_id != args.dig(:stage_id).to_i &&
                          args.dig(:stage_id).to_i.positive? && (stage = Stage.for_client(contact.client_id).find_by(id: args[:stage_id].to_i))

        contact.update(stage_id: stage.id)

        return unless stage.campaign_id.positive?

        Contacts::Campaigns::StartJob.perform_later(
          campaign_id: stage.campaign_id,
          client_id:   contact.client_id,
          contact_id:  contact.id,
          user_id:     contact.user_id
        )
      end
    end
  end
end
