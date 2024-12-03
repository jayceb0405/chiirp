# frozen_string_literal: true

# app/jobs/contacts/stop_and_stop_campaigns_job.rb
module Contacts
  module Campaigns
    class StartAndStopCampaignsJob < ApplicationJob
      # description of this job
      # Contacts::Campaigns::StartAndStopCampaignsJob.perform_now(contact: Contact.first, start_campaign_id: 1, stop_campaign_ids: [2, 3])
      # Contacts::Campaigns::StartAndStopCampaignsJob.set(wait_until: 1.day.from_now).perform_later(contact: Contact.first, start_campaign_id: 1, stop_campaign_ids: [2, 3])
      # Contacts::Campaigns::StartAndStopCampaignsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(contact: Contact.first, start_campaign_id: 1, stop_campaign_ids: [2, 3])
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'stop_and_start_contact_campaigns').to_s
      end

      # perform the ActiveJob
      # (req) contact_id:                 Integer
      # (req) start_campaign_id:          Integer
      # (req) stop_campaign_ids:          Array<Integer>
      # (opt) contact_estimate_id:        Integer
      # (opt) contact_invoice_id:         Integer
      # (opt) contact_job_id:             Integer
      # (opt) contact_location_id:        Integer
      # (opt) contact_membership_type_id: Integer
      # (opt) contact_subscription_id:    Integer
      # (opt) contact_visit_id:           Integer
      # (opt) st_membership_id:           Integer
      def perform(**args)
        super

        contact = Contact.find_by(id: args.delete(:contact_id))
        return unless contact

        contact.stop_and_start_contact_campaigns(**args)
      end
    end
  end
end
