# frozen_string_literal: true

# app/jobs/integrations/fieldpulse/v1/imports/contacts_job.rb
module Integrations
  module Fieldpulse
    module V1
      module Imports
        class ContactsJob < ApplicationJob
          # import Contacts from Fieldpulse clients
          # step 1 / get the Fieldpulse customers & create 1 Delayed::Job/(IMPORT_BLOCK_COUNT)
          # Integrations::Fieldpulse::V1::Imports::ContactsJob.perform_now()
          # Integrations::Fieldpulse::V1::Imports::ContactsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldpulse::V1::Imports::ContactsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldpulse_import_contacts').to_s
          end

          # perform the ActiveJob
          #   (opt) actions:   (Hash)
          #     see Integrations::Fieldpulse::V1::Imports::ContactActionsJob
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
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'fieldpulse', name: '')) &&
                          (fp_model = Integration::Fieldpulse::V1::Base.new(client_api_integration)) && fp_model.valid_credentials?

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

            run_at = Time.current
            page   = 1

            loop do
              fp_customers = fp_model.customers(page:)

              break if fp_customers.blank?

              fp_customers = fp_customers.select { |customer| !customer[:status]&.casecmp?('inactive') } if filter[:active_only]
              fp_customers = fp_customers.select { |customer| customer[:createdAt].between?(filter[:createdAt][:after], filter[:createdAt][:before]) } if filter[:createdAt].present?
              fp_customers = fp_customers.select { |customer| customer[:updatedAt].between?(filter[:updatedAt][:after], filter[:updatedAt][:before]) } if filter[:updatedAt].present?

              if fp_customers.blank?
                page += 1
                next
              end

              Integrations::Fieldpulse::V1::Imports::ContactsBlocksJob.set(wait_until: run_at).perform_later(
                client_id:    args[:client_id],
                fp_customers:,
                user_id:      args[:user_id]
              )

              run_at += Integrations::FieldPulse::V1::Base::IMPORT_BLOCK_COUNT.seconds
              page   += 1
            end

            Integration::Fieldpulse::V1::Base.new.import_contacts_remaining_update(args[:user_id], false)
          end
        end
      end
    end
  end
end
