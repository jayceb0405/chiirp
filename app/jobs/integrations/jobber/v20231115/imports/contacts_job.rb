# frozen_string_literal: true

# app/jobs/integrations/jobber/v20231115/imports/contacts_job.rb
module Integrations
  module Jobber
    module V20231115
      module Imports
        class ContactsJob < ApplicationJob
          # import Contacts from Jobber clients
          # step 1 / get the Jobber clients & create 1 Delayed::Job/(IMPORT_BLOCK_COUNT)
          # Integrations::Jobber::V20231115::Imports::ContactsJob.perform_now()
          # Integrations::Jobber::V20231115::Imports::ContactsJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Jobber::V20231115::Imports::ContactsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'jobber_import_contacts').to_s
          end

          # perform the ActiveJob
          #   (opt) actions:   (Hash)
          #     see Integrations::Jobber::V20231115::Imports::ContactActionsJob
          #   (req) client_id: (Integer)
          #   (opt) filter:    (Hash)
          #     (opt) is_company:  (Boolean)
          #     (opt) is_lead:     (Boolean)
          #     (opt) is_archived: (Boolean)
          #     (opt) updated_at   (Hash)
          #       (opt) after:  (DateTime)
          #       (opt) before: (DateTime)
          #     (opt) created_at:  (Hash)
          #       (opt) after:  (DateTime)
          #       (opt) before: (DateTime)
          #     (opt) tags:        (Array)
          #   (req) user_id:   (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'jobber', name: '')) &&
                          (jb_model = Integration::Jobber::V20231115::Base.new(client_api_integration)) && jb_model.valid_credentials? &&
                          (jb_client = Integrations::JobBer::V20231115::Base.new(client_api_integration.credentials))

            run_at              = Time.current
            end_cursor          = ''
            filter              = {}
            filter[:isArchived] = args[:filter][:is_archived].to_bool unless args.dig(:filter, :is_archived).nil?
            filter[:isCompany]  = args[:filter][:is_company].to_bool unless args.dig(:filter, :is_company).nil?
            filter[:isLead]     = args[:filter][:is_lead].to_bool unless args.dig(:filter, :is_lead).nil?

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

            filter[:tags] = args[:filter][:tags] if args.dig(:filter, :tags).present?

            loop do
              jb_client.clients(
                page_size:  Integration::Jobber::V20231115::Base::IMPORT_BLOCK_COUNT,
                end_cursor:,
                filter:
              )

              if jb_client.result.present?
                Integrations::Jobber::V20231115::Imports::ContactsBlocksJob.set(wait_until: run_at).perform_later(
                  actions:        args.dig(:actions),
                  client_id:      args[:client_id],
                  filter:,
                  jobber_clients: jb_client.result,
                  user_id:        args[:user_id]
                )
              end

              break unless jb_client.more_results

              end_cursor = jb_client.end_cursor
              run_at    += Integration::Jobber::V20231115::Base::IMPORT_BLOCK_COUNT.seconds
            end

            jb_model.import_contacts_remaining_update(args[:user_id], false)
          end
        end
      end
    end
  end
end
