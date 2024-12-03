# frozen_string_literal: true

# app/jobs/contacts/campaigns/start_job.rb
module Contacts
  module Campaigns
    class StartJob < ApplicationJob
      # start a Campaign on a Contact
      # Contacts::Campaigns::StartJob.set(wait_until: 1.day.from_now).perform_later()
      # Contacts::Campaigns::StartJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'start_campaign').to_s
      end

      # perform the ActiveJob
      #   (req) campaign_id:                (Integer
      #   (req) client_id:                  (Integer)
      #   (req) contact_id:                 (Integer)
      #
      #   (opt) contact_estimate_id:        (Integer)
      #   (opt) contact_invoice_id:         (Integer)
      #   (opt) contact_job_id:             (Integer)
      #   (opt) contact_location_id:        (Integer)
      #   (opt) contact_membership_type_id: (Integer)
      #   (opt) contact_subscription_id:    (Integer)
      #   (opt) contact_visit_id:           (Integer)
      #   (opt) group_process:              (Integer)
      #   (opt) group_uuid:                 (String)
      #   (opt) message_id:                 (Integer)
      #   (opt) st_membership_id:           (Integer)
      #   (opt) target_time:                (DateTime)
      #   (opt) user_id:                    (Integer)
      def perform(**args)
        super

        return false unless args.dig(:client_id).to_i.positive? && (client = Client.find_by(id: args[:client_id].to_i)).present? && client.active?

        unless args.dig(:contact_id).to_i.positive? && (@contact = client.contacts.find_by(id: args[:contact_id].to_i)).present?
          notify_user_of_error("Contact (#{args.dig(:contact_id).presence || 'Unknown'}) could NOT be found. The Campaign (#{args.dig(:campaign_id).presence || 'Unknown'}) could NOT be started.")
          return false
        end

        if args.dig(:campaign_id).to_i.zero? || (campaign = client.campaigns.find_by(id: args[:campaign_id].to_i)).blank?
          notify_user_of_error("Campaign (#{args[:campaign_id].presence || 'Unknown'}) could NOT be found. A Campaign could not be started for Contact (#{@contact.fullname}).")
          return false
        end

        return false unless campaign.repeatable?(@contact)

        unless campaign.active
          notify_user_of_error("Campaign (#{campaign.name}) could NOT be started for Contact (#{@contact.fullname}). The Campaign is NOT active.")
          return false
        end

        if client.integrations_allowed.include?('google') && client.client_api_integrations.find_by(target: 'google', name: '')&.review_campaign_ids_excluded&.include?(campaign.id) && Review.find_by(contact_id: @contact.id)
          notify_user_of_error("Campaign (#{campaign.name}) could NOT be started for Contact (#{@contact.fullname}). The Campaign is NOT allowed to start on Google reviews.")
          return false
        end

        unless (trigger = campaign.triggers.order(:step_numb).first) && (Trigger::FORWARD_TYPES + Trigger::REVERSE_TYPES + [155]).include?(trigger.trigger_type)
          notify_user_of_error("Campaign (#{campaign.name}) could NOT be started for Contact (#{contact.fullname}). The Campaign is NOT allowed to start in this manner.")
          return false
        end

        contact_campaign_data = {}
        contact_campaign_data[:contact_estimate_id]        = args[:contact_estimate_id] if args.dig(:contact_estimate_id).to_i.positive?
        contact_campaign_data[:contact_invoice_id]         = args[:contact_invoice_id] if args.dig(:contact_invoice_id).to_i.positive?
        contact_campaign_data[:contact_job_id]             = args[:contact_job_id] if args.dig(:contact_job_id).to_i.positive?
        contact_campaign_data[:contact_location_id]        = args[:contact_location_id] if args.dig(:contact_location_id).to_i.positive?
        contact_campaign_data[:contact_membership_type_id] = args[:contact_membership_type_id] if args.dig(:contact_membership_type_id).to_i.positive?
        contact_campaign_data[:contact_subscription_id]    = args[:contact_subscription_id] if args.dig(:contact_subscription_id).to_i.positive?
        contact_campaign_data[:contact_visit_id]           = args[:contact_visit_id] if args.dig(:contact_visit_id).to_i.positive?
        contact_campaign_data[:st_membership_id]           = args[:st_membership_id] if args.dig(:st_membership_id).to_i.positive?
        contact_campaign = @contact.contact_campaigns.create(campaign_id: campaign.id, data: contact_campaign_data)
        message          = args.dig(:message_id).to_i.positive? && Messages::Message.find_by(id: args[:message_id].to_i)

        trigger.fire(contact: @contact, contact_campaign:, message:, target_time: args.dig(:target_time).respond_to?(:strftime) ? args[:target_time] : nil)

        return true unless trigger.repeatable? && trigger.data.dig(:repeat).to_i == 1 && trigger.data.dig(:repeat_interval).to_i.positive? && trigger.data.dig(:repeat_period).to_s.present?

        # Trigger is repeatable
        Contacts::Campaigns::StartJob.set(wait_until: Time.current + trigger.data[:repeat_interval].to_i.send(trigger.data[:repeat_period].to_s)).perform_later(
          campaign_id:                campaign.id,
          client_id:                  client.id,
          contact_id:                 @contact.id,
          message:,
          contact_estimate_id:        args.dig(:contact_estimate_id),
          contact_invoice_id:         args.dig(:contact_invoice_id),
          contact_job_id:             args.dig(:contact_job_id),
          contact_location_id:        args.dig(:contact_location_id),
          contact_membership_type_id: args.dig(:contact_membership_type_id),
          contact_subscription_id:    args.dig(:contact_subscription_id),
          contact_visit_id:           args.dig(:contact_visit_id),
          st_membership_id:           args.dig(:st_membership_id),
          contact_campaign_id:        contact_campaign.id
        )

        true
      end

      private

      def notify_user_of_error(error_message)
        return if error_message.blank? || @contact.blank?

        Users::SendPushOrTextJob.perform_later(
          content:    error_message,
          contact_id: @contact.id,
          from_phone: @contact.user.default_from_twnumber&.phonenumber.to_s,
          ok2push:    @contact.user.notifications.dig('campaigns', 'by_push'),
          ok2text:    @contact.user.notifications.dig('campaigns', 'by_text'),
          to_phone:   @contact.user.phone,
          user_id:    @contact.user_id
        )
      end
    end
  end
end
