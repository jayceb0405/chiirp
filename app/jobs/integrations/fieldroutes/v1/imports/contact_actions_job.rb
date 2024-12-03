# frozen_string_literal: true

# app/jobs/integrations/fieldroutes/v1/imports/contact_actions_job.rb
module Integrations
  module Fieldroutes
    module V1
      module Imports
        class ContactActionsJob < ApplicationJob
          # description of this job
          # Integrations::Fieldroutes::V1::Imports::ContactActionsJob.perform_now()
          # Integrations::Fieldroutes::V1::Imports::ContactActionsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldroutes::V1::Imports::ContactActionsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldroutes_import_contact').to_s
          end

          # perform the ActiveJob
          #   (req) account_balance:  (BigDecimal)
          #   (req) actions:          (Hash)
          #     (opt) above_0: (Hash)
          #       (opt) import:            (Boolean)
          #       (opt) campaign_id:       (Integer)
          #       (opt) group_id:          (Integer)
          #       (opt) stage_id:          (Integer)
          #       (opt) tag_id:            (Integer)
          #       (opt) stop_campaign_ids: (Array)
          #     (opt) eq_0:    (Hash)
          #       (opt) import:            (Boolean)
          #       (opt) campaign_id:       (Integer)
          #       (opt) group_id:          (Integer)
          #       (opt) stage_id:          (Integer)
          #       (opt) tag_id:            (Integer)
          #       (opt) stop_campaign_ids: (Array)
          #     (opt) below_0: (Hash)
          #       (opt) import:            (Boolean)
          #       (opt) campaign_id:       (Integer)
          #       (opt) group_id:          (Integer)
          #       (opt) stage_id:          (Integer)
          #       (opt) tag_id:            (Integer)
          #       (opt) stop_campaign_ids: (Array)
          #   (req) client_id:        (Integer)
          #   (req) contact_id:       (Integer)
          #   (req) user_id:          (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          Integer(args.dig(:contact_id), exception: false).present? && args.dig(:actions).is_a?(Hash) && args.dig(:account_balance).is_a?(BigDecimal) &&
                          (contact = Contact.find_by(client_id: args[:client_id].to_i, id: args[:contact_id].to_i))

            # 0 balance actions
            if args[:account_balance].zero?
              contact.process_actions(
                campaign_id:       args.dig(:actions, :eq_0, :campaign_id).to_i,
                group_id:          args.dig(:actions, :eq_0, :group_id).to_i,
                stage_id:          args.dig(:actions, :eq_0, :stage_id).to_i,
                tag_id:            args.dig(:actions, :eq_0, :tag_id).to_i,
                stop_campaign_ids: args.dig(:actions, :eq_0, :stop_campaign_ids)
              )
            end

            # balance below 0 actions
            if args[:account_balance].negative?
              contact.process_actions(
                campaign_id:       args.dig(:actions, :below_0, :campaign_id).to_i,
                group_id:          args.dig(:actions, :below_0, :group_id).to_i,
                stage_id:          args.dig(:actions, :below_0, :stage_id).to_i,
                tag_id:            args.dig(:actions, :below_0, :tag_id).to_i,
                stop_campaign_ids: args.dig(:actions, :below_0, :stop_campaign_ids)
              )
            end

            # balance above 0 actions
            return unless args[:account_balance].positive?

            contact.process_actions(
              campaign_id:       args.dig(:actions, :above_0, :campaign_id).to_i,
              group_id:          args.dig(:actions, :above_0, :group_id).to_i,
              stage_id:          args.dig(:actions, :above_0, :stage_id).to_i,
              tag_id:            args.dig(:actions, :above_0, :tag_id).to_i,
              stop_campaign_ids: args.dig(:actions, :above_0, :stop_campaign_ids)
            )
          end
        end
      end
    end
  end
end
