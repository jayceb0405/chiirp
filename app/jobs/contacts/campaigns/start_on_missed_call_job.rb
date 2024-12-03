# frozen_string_literal: true

# app/jobs/contacts/campaigns/start_on_missed_call_job.rb
module Contacts
  module Campaigns
    class StartOnMissedCallJob < ApplicationJob
      # start a Campaign on a Contact after a missed call
      # Contacts::Campaigns::StartOnMissedCallJob.perform_now()
      # Contacts::Campaigns::StartOnMissedCallJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Campaigns::StartOnMissedCallJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'start_campaigns_on_missed_call').to_s
      end

      # perform the ActiveJob
      #   (req) client_id:                  (Integer)
      #   (req) client_phone_number:        (String)
      #   (req) contact_id:                 (Integer)
      def perform(**args)
        super

        return false unless Integer(args.dig(:client_id), exception: false).present? && args.dig(:client_phone_number).present? && Integer(args.dig(:contact_id), exception: false).present? &&
                            (client = Client.find_by(id: args[:client_id].to_i)) && (contact = client.contacts.find_by(id: args[:contact_id].to_i)) &&
                            (client_number = client.twnumbers.find_by(phonenumber: args[:client_phone_number].to_s)) &&
                            (new_contact_by_phone_triggers = Trigger.where(trigger_type: 152, campaign_id: client_number.client.campaigns))

        dayofweek = Time.current.in_time_zone(client_number.client.time_zone).strftime('%a').downcase
        minuteofday = (Time.current.in_time_zone(client_number.client.time_zone).hour * 60) + Time.current.in_time_zone(client_number.client.time_zone).min
        active_campaigns = contact.active_campaigns

        new_contact_by_phone_triggers.each do |trigger|
          if trigger.data&.include?(:phone_number) && (trigger.data[:phone_number].to_s.empty? || trigger.data[:phone_number].to_s == args[:client_phone_number].to_s) &&
             trigger.data&.include?(:new_contacts_only) && ((trigger.data[:new_contacts_only].to_i.positive? && contact.created_at > 15.minutes.ago) || trigger.data[:new_contacts_only].to_i.zero?) &&
             trigger.data&.include?(:process_times_a) && trigger.data&.include?(:process_times_b) &&
             (minuteofday.between?(trigger.data[:process_times_a].split(';')[0].to_i, trigger.data[:process_times_a].split(';')[1].to_i) ||
             minuteofday.between?(trigger.data[:process_times_b].split(';')[0].to_i, trigger.data[:process_times_b].split(';')[1].to_i)) &&
             trigger.data&.include?(:"process_#{dayofweek}") && trigger.data[:"process_#{dayofweek}"].to_i == 1 && active_campaigns.exclude?(trigger.campaign_id.to_i)

            Contacts::Campaigns::StartJob.perform_later(
              campaign_id: trigger.campaign_id,
              client_id:   contact.client_id,
              contact_id:  contact.id,
              user_id:     contact.user_id
            )
          end
        end
      end
    end
  end
end
