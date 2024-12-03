# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/balance/all_clients_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Balance
          class AllClientsJob < ApplicationJob
            # step 1 (all Clients)
            # update account balance for all ServiceTitan customers
            # Integrations::Servicetitan::V2::Customers::Balance::AllClientsJob.perform_now()
            # Integrations::Servicetitan::V2::Customers::Balance::AllClientsJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Balance::AllClientsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()

            def initialize(**args)
              super

              @process = (args.dig(:process).presence || 'servicetitan_customers_balance_all_clients').to_s
            end

            # perform the ActiveJob
            #   (opt) do_cgst: (Boolean)
            def perform(**args)
              super

              block_count = 4000 # less than maximum of 5000 since some Contacts have more than 1 ext_ref_id for ServiceTitan
              run_at      = Time.current

              Client.active.with_integration_allowed('servicetitan').find_each do |client|
                Integrations::Servicetitan::V2::Customers::Balance::ByClientJob.set(wait_until: run_at).perform_later(
                  block_count:,
                  client_id:   client.id,
                  do_cgst:     args.dig(:do_cgst)
                )

                run_at += 10.seconds
              end
            end
          end
        end
      end
    end
  end
end
