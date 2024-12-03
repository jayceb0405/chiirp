# frozen_string_literal: true

# app/jobs/integrations/jobber/v20231115/imports/contacts_blocks_job.rb
module Integrations
  module Jobber
    module V20231115
      module Imports
        class ContactsBlocksJob < ApplicationJob
          # import Contacts from Jobber clients
          # step 2 / get the (IMPORT_BLOCK_COUNT) Jobber clients and split into 1 Delayed::Job/contact
          # Integrations::Jobber::V20231115::Imports::ContactsBlocksJob.perform_now()
          # Integrations::Jobber::V20231115::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobber::V20231115::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobber_import_contacts_blocks').to_s
          end

          # perform the ActiveJob
          #   (req) actions:        (Hash)
          #     see Integrations::Jobber::V20231115::Imports::ContactActionsJob
          #   (req) client_id:      (Integer)
          #   (req) filter:         (Hash)
          #   (req) jobber_clients: (Array)
          #   (req) user_id:        (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:actions).is_a?(Hash) && args.dig(:filter).is_a?(Hash) && args.dig(:jobber_clients).is_a?(Array) &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'jobber', name: '')) &&
                          (jb_model = Integration::Jobber::V20231115::Base.new(client_api_integration)) && jb_model.valid_credentials?

            run_at = Time.current

            args.dig(:jobber_clients).each do |jobber_client|
              Integrations::Jobber::V20231115::Imports::ContactJob.set(wait_until: run_at).perform_later(
                actions:          args[:actions],
                client_id:        args[:client_id],
                jobber_client_id: jobber_client.dig(:id),
                user_id:          args[:user_id]
              )

              run_at += 1.second
            end

            jb_model.import_contacts_remaining_update(args[:user_id])
          end
        end
      end
    end
  end
end
