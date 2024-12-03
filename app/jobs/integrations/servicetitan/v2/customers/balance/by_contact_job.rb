# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/balance/by_contact_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Balance
          class ByContactJob < ApplicationJob
            # step 4 (a Contact)
            # update account balance for all ServiceTitan customers
            # Integrations::Servicetitan::V2::Customers::Balance::ByContactJob.perform_now()
            # Integrations::Servicetitan::V2::Customers::Balance::ByContactJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Balance::ByContactJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process = (args.dig(:process).presence || 'servicetitan_customers_balance_by_contact').to_s
            end

            # perform the ActiveJob
            #   (req) client_id:         (Integer)
            #   (req) contact_id:        (Integer)
            #   (opt) do_cgst:            (Boolean)
            #   (req) st_customer_model: (Hash)
            def perform(**args)
              super

              return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? && args.dig(:st_customer_model).is_a?(Hash) &&
                            (contact = Contact.find_by(id: args[:contact_id].to_i, client_id: args[:client_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: '')) &&
                            (contact_api_integration = ContactApiIntegration.find_by(contact_id: contact.id, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) && st_model.valid_credentials?

              previous_account_balance = contact_api_integration.account_balance.to_d

              contact_api_integration.update(account_balance: args[:st_customer_model].dig(:balance).to_d, update_balance_window_days: [0, contact_api_integration.update_balance_window_days - 1].max)
              st_model.update_contact_custom_fields(contact)

              return unless args.dig(:do_cgst).to_bool

              Integrations::Servicetitan::V2::Customers::Balance::BalanceActionsJob.perform_later(
                client_id:                args[:client_id],
                contact_id:               args[:contact_id],
                previous_account_balance:,
                current_account_balance:  contact_api_integration.account_balance.to_d
              )
            end
          end
        end
      end
    end
  end
end
