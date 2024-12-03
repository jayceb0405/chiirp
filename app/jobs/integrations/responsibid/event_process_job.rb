# frozen_string_literal: true

# app/jobs/integrations/responsibid/event_process_job.rb
module Integrations
  module Responsibid
    class EventProcessJob < ApplicationJob
      # process ResponsiBid events
      # Integrations::Responsibid::EventProcessJob.perform_now()
      # Integrations::Responsibid::EventProcessJob.set(wait_until: 1.day.from_now).perform_later()
      # Integrations::Responsibid::EventProcessJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'responsibid_process_event').to_s
      end

      # perform the ActiveJob
      #   (req) client_api_integration_id: (Integer)
      #   (req) client_id:                 (Integer)
      #   (req) parsed_webhook:            (Hash)
      #   (req) raw_params:                (Hash)
      #
      #   (opt) event_id:                  (String / default: nil)
      def perform(**args)
        super

        return unless Integer(args.dig(:client_api_integration_id), exception: false).present? && Integer(args.dig(:client_id), exception: false).present? &&
                      args.dig(:parsed_webhook).is_a?(Hash) && args.dig(:raw_params).present? &&
                      (client_api_integration = ClientApiIntegration.find_by(id: args[:client_api_integration_id].to_i, client_id: args[:client_id].to_i, target: 'responsibid', name: '')) &&
                      (contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: args[:client_id].to_i, phones: args.dig(:parsed_webhook, :contact, :phones), emails: args.dig(:parsed_webhook, :contact, :email), ext_refs: { 'responsibid' => args.dig(:parsed_webhook, :contact, :ext_id) }))

        contact.lastname   = args.dig(:parsed_webhook, :contact, :lastname) if args.dig(:parsed_webhook, :contact, :lastname).present?
        contact.firstname  = args.dig(:parsed_webhook, :contact, :firstname) if args.dig(:parsed_webhook, :contact, :firstname).present?
        contact.address1   = args.dig(:parsed_webhook, :contact, :address_01) if args.dig(:parsed_webhook, :contact, :address_01).present?
        contact.address2   = args.dig(:parsed_webhook, :contact, :address_02) if args.dig(:parsed_webhook, :contact, :address_02).present?
        contact.city       = args.dig(:parsed_webhook, :contact, :city) if args.dig(:parsed_webhook, :contact, :city).present?
        contact.state      = args.dig(:parsed_webhook, :contact, :state) if args.dig(:parsed_webhook, :contact, :state).present?
        contact.zipcode    = args.dig(:parsed_webhook, :contact, :zipcode) if args.dig(:parsed_webhook, :contact, :zipcode).present?
        contact.ok2text    = args.dig(:parsed_webhook, :contact, :explicit_sms_opt_in).to_bool ? 1 : 0 if contact.ok2text.to_i.positive? && args.dig(:parsed_webhook, :contact, :explicit_sms_opt_in).present?
        contact.ok2email   = args.dig(:parsed_webhook, :contact, :explicit_opt_in).to_bool ? 1 : 0 if contact.ok2email.to_i.positive? && args.dig(:parsed_webhook, :contact, :explicit_opt_in).present?

        return unless contact.save

        if args.dig(:parsed_webhook, :contact, :ext_id).present?
          contact_ext_reference = contact.ext_references.find_or_initialize_by(target: 'responsibid')
          contact_ext_reference.update(ext_id: args.dig(:parsed_webhook, :contact, :ext_id))
        end

        event_new = contact.raw_posts.where(ext_source: 'responsibid').where('data @> ?', { Contact: { id: args.dig(:parsed_webhook, :contact, :ext_id) } }.to_json).order(created_at: :desc)&.first&.ext_id != args.dig(:parsed_webhook, :event_status)

        # save params to Contact::RawPosts
        contact.raw_posts.create(ext_source: 'responsibid', ext_id: args.dig(:parsed_webhook, :event_status), data: args[:raw_params])

        # add webhook events as needed
        Integration::Responsibid.update_custom_events(client_api_integration:, webhook_event: args.dig(:parsed_webhook, :event_status).to_s)

        # save Contacts::Estimate
        contact_estimate_id = Integration::Responsibid.update_estimate(contact, args[:parsed_webhook])

        # process defined actions for webhook
        Integrations::Responsibid::ProcessActionsForWebhookJob.perform_later(
          client_id:           args[:client_id],
          commercial:          args.dig(:parsed_webhook, :commercial).to_bool,
          contact_estimate_id:,
          contact_id:          contact.id,
          event_id:            args.dig(:event_id),
          event_new:,
          event_status:        args.dig(:parsed_webhook, :event_status).to_s,
          residential:         args.dig(:parsed_webhook, :residential).to_bool,
          user_id:             contact.user_id
        )
      end
    end
  end
end
