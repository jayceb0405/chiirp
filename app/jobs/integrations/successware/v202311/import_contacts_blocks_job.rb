# frozen_string_literal: true

# app/jobs/integrations/successware/v202311/import_contacts_blocks_job.rb
module Integrations
  module Successware
    module V202311
      class ImportContactsBlocksJob < ApplicationJob
        # Integrations::Successware::V202311::ImportContactsBlocksJob.set(wait_until: 1.day.from_now).perform_later()
        # Integrations::Successware::V202311::ImportContactsBlocksJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

        def initialize(**args)
          super

          @process          = (args.dig(:process).presence || 'successware_import_contacts_blocks').to_s
          @reschedule_secs  = 0
        end

        # import Contacts from Successware clients
        # step 2 / get the (IMPORT_BLOCK_COUNT) Successware clients and split into 1 Delayed::Job / contact
        # perform the ActiveJob
        #   (opt) filter:  (Hash)
        #     (opt) commercial:  (Boolean)
        #     (opt) residential: (Boolean)
        #   (opt) actions: (Hash)
        #     see import_contact_actions
        #   (req) successware_customers: (Array)
        #   (req) user_id:               (Integer)
        def perform(**args)
          super

          args = args.deep_symbolize_keys

          return unless args.dig(:actions).is_a?(Hash) && args.dig(:filter).is_a?(Hash) && args.dig(:successware_customers).is_a?(Array)
          return unless args.dig(:user_id).to_i.positive? && (user = User.find_by(id: args[:user_id]))
          return unless (client_api_integration = user.client.client_api_integrations.find_by(target: 'successware', name: ''))
          return unless (sw_model = Integration::Successware::V202311::Base.new(client_api_integration)) && sw_model.valid_credentials?

          run_at = Time.current

          args.dig(:successware_customers).each do |successware_customer|
            next unless (args.dig(:filter, :commercial).to_bool && args.dig(:filter, :is_company, :residential).to_bool) ||
                        (args.dig(:filter, :commercial).to_bool && successware_customer.dig(:customer, :commercial).to_bool) ||
                        (args.dig(:filter, :residential).to_bool && !successware_customer.dig(:customer, :commercial).to_bool)
            next unless (args[:actions][:eq_0][:import].to_bool && args[:actions][:below_0][:import].to_bool && args[:actions][:above_0][:import].to_bool) ||
                        (args[:actions][:eq_0][:import].to_bool && successware_customer.dig(:billingAccountOutput, :mainArBillingCustomer)&.first&.dig(:balanceDue).to_d.zero?) ||
                        (args[:actions][:below_0][:import].to_bool && successware_customer.dig(:billingAccountOutput, :mainArBillingCustomer)&.first&.dig(:balanceDue).to_d.negative?) ||
                        (args[:actions][:above_0][:import].to_bool && successware_customer.dig(:billingAccountOutput, :mainArBillingCustomer)&.first&.dig(:balanceDue).to_d.positive?)

            Integrations::Successware::V202311::ImportContactJob.set(wait_until: run_at).perform_later(
              actions:              args[:actions],
              successware_customer:,
              user_id:              args[:user_id]
            )

            run_at += 1.second
          end

          sw_model.import_contacts_remaining_update(args[:user_id])
        end
      end
    end
  end
end
