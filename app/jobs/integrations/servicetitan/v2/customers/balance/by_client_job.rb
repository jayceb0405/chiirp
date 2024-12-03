# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/balance/by_client_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Balance
          class ByClientJob < ApplicationJob
            # step 2 (a Client)
            # update account balance for all ServiceTitan customers
            # Integrations::Servicetitan::V2::Customers::Balance::ByClientJob.perform_now()
            # Integrations::Servicetitan::V2::Customers::Balance::ByClientJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Balance::ByClientJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(

            def initialize(**args)
              super

              @process = (args.dig(:process).presence || 'servicetitan_customers_balance_by_client').to_s
            end

            # perform the ActiveJob
            #   (opt) block_count: (Integer / default: 4000)
            #   (req) client_id:   (Integer)
            #   (opt) do_cgst:      (Boolean)
            def perform(**args)
              super

              return unless Integer(args.dig(:client_id), exception: false).present? && (client = Client.find_by(id: args[:client_id].to_i))

              run_at = Time.current

              all_contact_ids = client.contacts
                                      .joins(:contact_api_integrations)
                                      .where(contact_api_integrations: { target: 'servicetitan' })
                                      .where("(contact_api_integrations.data->>'account_balance')::numeric > ?", 0)
                                      .where("(contact_api_integrations.data->>'update_balance_window_days')::numeric > ?", 0)
                                      .where.not(contacts: { id: DelayedJob.select(:contact_id).where(user_id: User.select(:id).where(client_id: client.id), process: 'servicetitan_update_balance') })
                                      .pluck(:id)

              all_contact_ids.in_groups_of((args.dig(:block_count) || 4000).to_i, false).each do |contact_ids|
                Integrations::Servicetitan::V2::Customers::Balance::ByClientPageJob.set(wait_until: run_at).perform_later(
                  client_id:   args[:client_id],
                  contact_ids:,
                  do_cgst:     args.dig(:do_cgst)
                )

                run_at += 1.minute
              end
            end
          end
        end
      end
    end
  end
end
