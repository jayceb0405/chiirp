# frozen_string_literal: true

# app/jobs/contacts/notes/new_job.rb
module Contacts
  module Notes
    class NewJob < ApplicationJob
      # add a Contacts::Note to a Contact
      # Contacts::Notes::NewJob.perform_now()
      # Contacts::Notes::NewJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Notes::NewJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'create_note').to_s
      end

      # perform the ActiveJob
      #   (req) contact_id:          (Integer
      #   (req) note:                (String)
      #   (req) user_id:             (Integer)
      #
      #   (opt) contact_campaign_id: (Integer)
      def perform(**args)
        super

        return false if args.dig(:note).to_s.blank?
        return false unless args.dig(:contact_id).to_i.positive? && (contact = Contact.find_by(id: args[:contact_id].to_i)).present? && contact.client.active?
        return false unless ((args.dig(:user_id).to_i.positive? && (user = User.find_by(id: args[:user_id].to_i)).present?) ||
                            (args.dig(:user_id).to_i.zero? && (user = contact.user).present?)) && !user.suspended?

        note = contact.message_tag_replace(args[:note].to_s)

        if args.dig(:contact_campaign_id).to_i.positive? && (contact_campaign = contact.campaigns.find_by(id: args[:contact_campaign_id].to_i))
          if contact_campaign.data.dig(:contact_estimate_id).to_i.positive? && (contact_estimate = contact.estimates.find_by(id: contact_campaign.data[:contact_estimate_id]))
            note = contact_estimate.message_tag_replace(note)
          end

          if contact_campaign.data.dig(:contact_invoice_id).to_i.positive? && (contact_invoice = contact.invoices.find_by(id: contact_campaign.data[:contact_invoice_id]))
            note = contact_invoice.message_tag_replace(note)
          end

          if contact_campaign.data.dig(:contact_job_id).to_i.positive? && (contact_job = contact.jobs.find_by(id: contact_campaign.data[:contact_job_id]))
            note = contact_job.message_tag_replace(note)
          end

          if contact_campaign.data.dig(:contact_subscription_id).to_i.positive? && (contact_subscription = contact.subscriptions.find_by(id: contact_campaign.data[:contact_subscription_id]))
            note = contact_subscription.message_tag_replace(note)
          end

          if contact_campaign.data.dig(:contact_visit_id).to_i.positive? && (contact_visit = contact.visits.find_by(id: contact_campaign.data[:contact_visit_id]))
            note = contact_visit.message_tag_replace(note)
          end
        end

        return false unless contact.notes.create(user_id: user.id, note:)

        true
      end
    end
  end
end
