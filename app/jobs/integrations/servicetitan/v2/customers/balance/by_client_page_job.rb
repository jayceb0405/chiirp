# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/balance/by_client_page_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Balance
          class ByClientPageJob < ApplicationJob
            # step 3 (a Client Page)
            # update account balance for all ServiceTitan customers
            # Integrations::Servicetitan::V2::Customers::Balance::ByClientPageJob.perform_now()
            # Integrations::Servicetitan::V2::Customers::Balance::ByClientPageJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Balance::ByClientPageJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
            def initialize(**args)
              super

              @process = (args.dig(:process).presence || 'servicetitan_customers_balance_by_client_page').to_s
            end

            # perform the ActiveJob
            #   (req) client_id:   (Integer)
            #   (req) contact_ids: (Array)
            #   (opt) do_cgst:      (Boolean)
            def perform(**args)
              super

              return unless Integer(args.dig(:client_id), exception: false).present? && args.dig(:contact_ids).is_a?(Array) && args[:contact_ids].present? &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'servicetitan', name: '')) &&
                            (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) &&
                            st_model.valid_credentials? &&
                            (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

              st_customer_models = []

              Contacts::ExtReference.where(contact_id: args[:contact_ids], target: 'servicetitan').pluck(:ext_id).uniq.in_groups_of(50, false) do |st_customer_model_ids|
                st_customer_models += st_client.customers(st_customer_ids: st_customer_model_ids)
              end

              run_at = Time.current

              Contact.where(id: args[:contact_ids]).includes(:ext_references).each do |contact|
                contact.ext_references.pluck(:ext_id).each do |ext_reference|
                  if (st_customer_model = st_customer_models.find { |cm| cm[:id] == ext_reference.to_i })
                    Integrations::Servicetitan::V2::Customers::Balance::ByContactJob.set(wait_until: run_at).perform_later(
                      client_id:         args[:client_id],
                      contact_id:        contact.id,
                      do_cgst:           args.dig(:do_cgst),
                      st_customer_model:
                    )

                    run_at += 1.second
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
