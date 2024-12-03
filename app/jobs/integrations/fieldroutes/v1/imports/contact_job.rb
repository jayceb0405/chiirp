# frozen_string_literal: true

# app/jobs/integrations/fieldroutes/v1/imports/contact_job.rb
module Integrations
  module Fieldroutes
    module V1
      module Imports
        class ContactJob < ApplicationJob
          # import Contacts from Fieldroutes clients
          # step 3 / import the Fieldroutes client
          # Integrations::Fieldroutes::V1::Imports::ContactJob.perform_now()
          # Integrations::Fieldroutes::V1::Imports::ContactJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Fieldroutes::V1::Imports::ContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process = (args.dig(:process).presence || 'fieldroutes_import_contact').to_s
          end

          # perform the ActiveJob
          #   (req) actions:        (Hash)
          #     see Integrations::Fieldroutes::V1::Imports::ContactActionsJob
          #   (req) client_id:      (Integer)
          #   (req) fr_customer_id: (String)
          #   (req) user_id:        (Integer)
          def perform(**args)
            super

            return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:user_id), exception: false).present? &&
                          args.dig(:actions).is_a?(Hash) && Integer(args.dig(:fr_customer_id), exception: false).present? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'fieldroutes', name: '')) &&
                          (fr_model = Integration::Fieldroutes::V1::Base.new(client_api_integration)) && fr_model.valid_credentials?

            fr_customer = fr_model.customer(args[:fr_customer_id])

            raise(MaxReadRequestsPerMinuteException) if !fr_model.success? && fr_model.error == 429 && fr_model.message.include?('requests per minute')
            raise(MaxReadRequestsPerDayException) if !fr_model.success? && fr_model.error == 429 && fr_model.message.include?('requests per day')

            contact = nil

            if fr_model.success? && ((!args.dig(:actions, :eq_0, :import).to_bool && !args.dig(:actions, :below_0, :import).to_bool && !args.dig(:actions, :above_0, :import).to_bool) ||
               (args.dig(:actions, :eq_0, :import).to_bool && fr_customer.dig(:balance).to_d.zero?) ||
               (args.dig(:actions, :below_0, :import).to_bool && fr_customer.dig(:balance).to_d.negative?) ||
               (args.dig(:actions, :above_0, :import).to_bool && fr_customer.dig(:balance).to_d.positive?))

              return false unless (contact = fr_model.contact(**fr_customer))

              if contact.present?
                Integrations::Fieldroutes::V1::Imports::ContactActionsJob.perform_now(
                  account_balance: fr_customer.dig(:balance).to_d,
                  actions:         args[:actions],
                  client_id:       args[:client_id],
                  contact_id:      contact.id,
                  user_id:         args[:user_id]
                )
              else
                Rails.logger.info "Integration::Fieldroutes::V1::Imports.import_contact: #{{ client_id: args[:client_id], contact_id: contact.id, errors: contact.errors.full_messages, contact_phones: contact.contact_phones }.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"
              end
            end

            Integration::Fieldroutes::V1::Base.new.import_contacts_remaining_update(args[:user_id])
          end
        end
      end
    end
  end
end
