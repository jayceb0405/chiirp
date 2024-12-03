# frozen_string_literal: true

# app/jobs/integrations/fieldroutes/v1/imports/contacts_job.rb
module Integrations
  module Fieldroutes
    module V1
      module Imports
        class ContactsJob < ApplicationJob
          # import Contacts from Fieldroutes clients
          # step 1 / get the Fieldroutes customers & create 1 Delayed::Job/(IMPORT_BLOCK_COUNT)
          # Integrations::Fieldroutes::V1::Imports::ContactsJob.perform_now()
          # Integrations::Fieldroutes::V1::Imports::ContactsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldroutes::V1::Imports::ContactsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldroutes_import_contacts').to_s
          end

          # perform the ActiveJob
          #   (opt) actions:   (Hash)
          #     see Integrations::Fieldroutes::V1::Imports::ContactActionsJob
          #   (req) client_id: (Integer)
          #   (opt) filter:    (Hash)
          #     (opt) active_only: (Boolean)
          #     (opt) updated_at   (Hash)
          #       (opt) after:  (DateTime)
          #       (opt) before: (DateTime)
          #     (opt) created_at:  (Hash)
          #       (opt) after:  (DateTime)
          #       (opt) before: (DateTime)
          #   (req) user_id:   (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'fieldroutes', name: '')) &&
                          (fr_model = Integration::Fieldroutes::V1::Base.new(client_api_integration)) && fr_model.valid_credentials?

            filter               = {}
            filter[:active_only] = args[:filter][:active_only].to_bool unless args.dig(:filter, :active_only).nil?

            if args.dig(:filter, :created_at, :before).respond_to?(:iso8601) || args.dig(:filter, :created_at, :after).respond_to?(:iso8601)
              filter[:createdAt]          = {}
              filter[:createdAt][:after]  = args[:filter][:created_at][:after].iso8601 if args.dig(:filter, :created_at, :after).respond_to?(:iso8601)
              filter[:createdAt][:before] = args[:filter][:created_at][:before].iso8601 if args.dig(:filter, :created_at, :before).respond_to?(:iso8601)
            end

            if args.dig(:filter, :updated_at, :before).respond_to?(:iso8601) || args.dig(:filter, :updated_at, :after).respond_to?(:iso8601)
              filter[:updatedAt]          = {}
              filter[:updatedAt][:after]  = args[:filter][:updated_at][:after].iso8601 if args.dig(:filter, :updated_at, :after).respond_to?(:iso8601)
              filter[:updatedAt][:before] = args[:filter][:updated_at][:before].iso8601 if args.dig(:filter, :updated_at, :before).respond_to?(:iso8601)
            end

            fr_customer_ids = fr_model.customer_ids(filter)

            raise(MaxReadRequestsPerMinuteException) if !fr_model.success? && fr_model.error == 429 && fr_model.message.include?('requests per minute')
            raise(MaxReadRequestsPerDayException) if !fr_model.success? && fr_model.error == 429 && fr_model.message.include?('requests per day')

            run_at = Time.current

            fr_customer_ids.in_groups_of(Integration::Fieldroutes::V1::Base::IMPORT_BLOCK_COUNT, false).each do |fr_customer_ids_block|
              Integrations::Fieldroutes::V1::Imports::ContactsBlocksJob.set(wait_until: run_at).perform_later(
                actions:         args.dig(:actions),
                client_id:       args[:client_id],
                fr_customer_ids: fr_customer_ids_block,
                user_id:         args[:user_id]
              )

              run_at += Integration::Fieldroutes::V1::Base::IMPORT_BLOCK_COUNT.seconds
            end

            Integration::Fieldroutes::V1::Base.new.import_contacts_remaining_update(args[:user_id], false)
          end
        end
      end
    end
  end
end
