# frozen_string_literal: true

# app/jobs/integrations/responsibid/process_actions_for_webhook_job.rb
module Integrations
  module Responsibid
    class ProcessActionsForWebhookJob < ApplicationJob
      # process defined actions for a ResponsiBid webhook event
      # Integrations::Responsibid::ProcessActionsForWebhookJob.perform_now()
      # Integrations::Responsibid::ProcessActionsForWebhookJob.set(wait_until: 1.day.from_now).perform_later()
      # Integrations::Responsibid::ProcessActionsForWebhookJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'process_actions_for_webhook').to_s
      end

      # perform the ActiveJob
      #   (req) client_id:              (Integer)
      #   (req) contact_id:             (Integer)
      #   (req) event_status:           (String)
      #
      #   (opt) commercial:             (Boolean / default: false)
      #   (opt) contact_estimate_id:    (Integer / default: nil)
      #   (opt) event_id:               (String / default: nil)
      #   (opt) event_new:              (Boolean / default: false)
      #   (opt) residential:            (Boolean / default: false)
      #   (opt) user_id:                (Integer / default: nil)
      def perform(**args)
        super

        return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? && args.dig(:event_status).to_s.present? &&
                      (contact = Contact.find_by(id: args[:contact_id].to_i, client_id: args[:client_id].to_i)) &&
                      (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'responsibid', name: ''))

        client_api_integration.webhooks.deep_symbolize_keys.dig(args[:event_status].to_sym)&.each do |webhook_event|
          next unless (args.dig(:event_id).present? && webhook_event.dig(:event_id).to_s == args.dig(:event_id).to_s) ||
                      ((args.dig(:event_id).blank? && (webhook_event.dig(:criteria, :event_new).to_bool && args.dig(:event_new).to_bool)) || (webhook_event.dig(:criteria, :event_updated).to_bool && !args.dig(:event_new).to_bool))

          contact.process_actions(
            campaign_id:         webhook_event.dig(:actions, :campaign_id),
            group_id:            webhook_event.dig(:actions, :group_id),
            stage_id:            webhook_event.dig(:actions, :stage_id),
            tag_id:              webhook_event.dig(:actions, :tag_id),
            stop_campaign_ids:   webhook_event.dig(:actions, :stop_campaign_ids),
            contact_estimate_id: args.dig(:contact_estimate_id)
          )
        end
      end
    end
  end
end
