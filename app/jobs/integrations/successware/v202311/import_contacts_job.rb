# frozen_string_literal: true

# app/jobs/integrations/successware/v202311/import_contacts_job.rb
module Integrations
  module Successware
    module V202311
      class ImportContactsJob < ApplicationJob
        # Integrations::Successware::V202311::ImportContactsJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Successware::V202311::ImportContactsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

        def initialize(**args)
          super

          @process          = (args.dig(:process).presence || 'successware_import_contacts').to_s
          @reschedule_secs  = 0
        end

        # import Contacts from Successware clients
        # step 1 / get the Successware clients & create 1 Delayed::Job for each (IMPORT_BLOCK_COUNT)
        # perform the ActiveJob
        #   (opt) actions: (Hash)
        #     see import_contact_actions
        #   (opt) filter:  (Hash)
        #     (opt) commercial:  (Boolean)
        #     (opt) residential: (Boolean)
        #   (opt) page:    (Integer)
        #   (req) user_id: (Integer)
        def perform(**args)
          super

          args = args.deep_symbolize_keys

          return unless args.dig(:user_id).to_i.positive? && (user = User.find_by(id: args[:user_id]))
          return unless (client_api_integration = user.client.client_api_integrations.find_by(target: 'successware', name: ''))
          return unless (sw_model = Integration::Successware::V202311::Base.new(client_api_integration)) && sw_model.valid_credentials?
          return unless (sw_client = Integrations::SuccessWare::V202311::Base.new(client_api_integration.credentials))

          run_at = Time.current
          sw_client.customers(page: args.dig(:page).to_i)

          if sw_client.success?
            Integrations::Successware::V202311::ImportContactsBlocksJob.set(wait_until: run_at, priority: 0).perform_later(
              actions:               args.dig(:actions),
              filter:                args.dig(:filter),
              successware_customers: sw_client.result.dig(:content),
              user_id:               args[:user_id]
            )

            sw_model.import_contacts_remaining_update(args[:user_id])

            if args.dig(:page).nil?
              run_at = Integration::Successware::V202311::Base::IMPORT_BLOCK_COUNT.seconds.from_now

              Array(1..sw_client.result.dig(:totalPages).to_i).each do |page|
                Integrations::Successware::V202311::ImportContactsJob.set(wait_until: run_at).perform_later(
                  actions: args.dig(:actions),
                  filter:  args.dig(:filter),
                  page:,
                  user_id: args[:user_id]
                )

                run_at += Integration::Successware::V202311::Base::IMPORT_BLOCK_COUNT.seconds

                sw_model.import_contacts_remaining_update(args[:user_id]) if (page % 10).zero?
              end
            end
          end

          sw_model.import_contacts_remaining_update(args[:user_id])
        end
      end
    end
  end
end
