# frozen_string_literal: true

# app/jobs/integrations/jobnimbus/v1/imports/contacts_blocks_job.rb
module Integrations
  module Jobnimbus
    module V1
      module Imports
        class ContactsBlocksJob < ApplicationJob
          # import Contacts from JobNimbus clients
          # step 2 / get the (IMPORT_BLOCK_COUNT) JobNimbus clients and split into 1 Integrations::Jobnimbus::V1::Imports.contact_job/contact
          # Integrations::Jobnimbus::V1::Imports::ContactsBlocksJob.perform_now()
          # Integrations::Jobnimbus::V1::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobnimbus::V1::Imports::ContactsBlocksJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobnimbus_import_contacts_blocks').to_s
          end

          # perform the ActiveJob
          #   (req) client_id:         (Integer)
          #   (req) user_id:           (Integer)
          #   (req) page_index:        (Integer)
          #
          #   (opt) new_contacts_only: (Boolean / default: false)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? && Integer(args.dig(:page_index), exception: false).present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'jobnimbus', name: '')) &&
                          (jn_model = Integration::Jobnimbus::V1::Base.new(client_api_integration)) && jn_model.valid_credentials? &&
                          (jn_client = Integrations::JobNimbus::V1::Base.new(client_api_integration.api_key))

            jn_client.contacts(page_index: args[:page_index].to_i, page_size: Integration::Jobnimbus::V1::Base::IMPORT_BLOCK_COUNT).dig(:results)&.each do |jn_contact|
              Integrations::Jobnimbus::V1::Imports::ContactJob.perform_later(
                client_id:         client_api_integration.client_id,
                user_id:           args[:user_id],
                jn_contact:,
                new_contacts_only: args.dig(:new_contacts_only)
              )
            end

            CableBroadcaster.new.contacts_import_remaining(client: client_api_integration.client_id, count: jn_model.contact_imports_remaining_string)
          end
        end
      end
    end
  end
end
