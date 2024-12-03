# frozen_string_literal: true

# app/jobs/integrations/fieldroutes/v1/imports/contacts_blocks_job.rb
module Integrations
  module Fieldroutes
    module V1
      module Imports
        class ContactsBlocksJob < ApplicationJob
          # import Contacts from Fieldroutes clients
          # step 2 / get the (IMPORT_BLOCK_COUNT) Fieldroutes clients and split into 1 Delayed::Job/contact
          # Integrations::Fieldroutes::V1::Imports::ContactsBlocksJob.perform_now()
          # Integrations::Fieldroutes::V1::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldroutes::V1::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldroutes_import_contacts_blocks').to_s
          end

          # perform the ActiveJob
          #   (req) actions:         (Hash)
          #     see Integrations::Fieldroutes::V1::Imports::ContactActionsJob
          #   (req) client_id:       (Integer)
          #   (req) fr_customer_ids: (Array)
          #   (req) user_id:         (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:actions).is_a?(Hash) && args.dig(:fr_customer_ids).is_a?(Array)

            run_at = Time.current

            args.dig(:fr_customer_ids).each do |fr_customer_id|
              Integrations::Fieldroutes::V1::Imports::ContactJob.set(wait_until: run_at).perform_later(
                actions:        args[:actions],
                client_id:      args[:client_id],
                fr_customer_id:,
                user_id:        args[:user_id]
              )

              run_at += 1.second
            end

            Integration::Fieldroutes::V1::Base.new.import_contacts_remaining_update(args[:user_id])
          end
        end
      end
    end
  end
end
