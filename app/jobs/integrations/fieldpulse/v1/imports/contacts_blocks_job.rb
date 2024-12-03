# frozen_string_literal: true

# app/jobs/integrations/fieldpulse/v1/imports/contacts_blocks_job.rb
module Integrations
  module Fieldpulse
    module V1
      module Imports
        class ContactsBlocksJob < ApplicationJob
          # import Contacts from Fieldpulse clients
          # step 2 / get the (IMPORT_BLOCK_COUNT) Fieldpulse clients and split into 1 Delayed::Job/contact
          # Integrations::Fieldpulse::V1::Imports::ContactsBlocksJob.perform_now()
          # Integrations::Fieldpulse::V1::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldpulse::V1::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldpulse_import_contacts_blocks').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:    (Integer)
          #   (req) fp_customers: (Array)
          #   (req) user_id:      (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:fp_customers).is_a?(Array)

            run_at = Time.current

            args[:fp_customers].each do |fp_customer|
              Integrations::Fieldpulse::V1::Imports::ContactJob.set(wait_until: run_at).perform_later(
                client_id:   args[:client_id],
                fp_customer:,
                user_id:     args[:user_id]
              )

              run_at += 1.second
            end

            Integration::Fieldpulse::V1::Base.new.import_contacts_remaining_update(args[:user_id])
          end
        end
      end
    end
  end
end
