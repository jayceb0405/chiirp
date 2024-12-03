# frozen_string_literal: true

# app/jobs/integrations/jobnimbus/v1/imports/contacts_job.rb
module Integrations
  module Jobnimbus
    module V1
      module Imports
        class ContactsJob < ApplicationJob
          # import Contacts from JobNimbus clients
          # step 1 / get the JobNimbus clients & create 1 Integrations::Jobnimbus::V1::Imports.contacts_blocks_job/(IMPORT_BLOCK_COUNT)
          # Integrations::Jobnimbus::V1::Imports::ContactsJob.perform_now()
          # Integrations::Jobnimbus::V1::Imports::ContactsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobnimbus::V1::Imports::ContactsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobnimbus_import_contacts').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:         (Integer)
          #   (req) user_id:           (Integer)
          #
          #   (opt) new_contacts_only: (Boolean / default: false)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'jobnimbus', name: '')) &&
                          (jn_model = Integration::Jobnimbus::V1::Base.new(client_api_integration)) && jn_model.valid_credentials?

            page_index = 0
            page_count = Integrations::JobNimbus::V1::Base.new(client_api_integration.api_key).contacts_count.to_i.divmod(Integration::Jobnimbus::V1::Base::IMPORT_BLOCK_COUNT)
            page_count = page_count[0] + (page_count[1].positive? ? 1 : 0)
            run_at     = Time.current

            while page_index < page_count
              Integrations::Jobnimbus::V1::Imports::ContactsBlocksJob.set(wait_until: run_at).perform_later(
                client_id:         client_api_integration.client_id,
                user_id:           args[:user_id],
                page_index:,
                new_contacts_only: args.dig(:new_contacts_only)
              )

              page_index += 1
              run_at     += Integration::Jobnimbus::V1::Base::IMPORT_BLOCK_COUNT.seconds
            end

            CableBroadcaster.new.contacts_import_remaining(client: client_api_integration.client_id, count: jn_model.contact_imports_remaining_string)
          end
        end
      end
    end
  end
end
