# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/memberships/events_by_client_page_job.rb
module Integrations
  module Servicetitan
    module V2
      module Memberships
        class EventsByClientPageJob < ApplicationJob
          # Step #3: trigger events for membership expirations for a Client (by page)
          # Integrations::Servicetitan::V2::Memberships::EventsByClientPageJob.set(wait_until: 1.day.from_now).perform_later()
          # Integrations::Servicetitan::V2::Memberships::EventsByClientPageJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
          def initialize(**args)
            super

            @process          = (args.dig(:process).presence || 'servicetitan_membership_events_by_client_page').to_s
            @reschedule_secs  = 0
          end

          # perform the ActiveJob
          #   (req) block_count: (Integer)
          #   (req) client_id:   (Integer)
          #   (req) page:        (Integer)
          def perform(**args)
            super

            return unless args.dig(:block_count).to_i.positive? && args.dig(:client_id).to_i.positive? && args.dig(:page).to_i.positive? &&
                          (client_api_integration = ClientApiIntegration.find_by(client_id: args.dig(:client_id).to_i, target: 'servicetitan', name: '')) &&
                          (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)) &&
                          st_model.valid_credentials? &&
                          (st_client = Integrations::ServiceTitan::Base.new(client_api_integration.credentials))

            st_membership_models = st_client.customer_memberships(active_only: true, status: 'Active', page_size: args[:block_count].to_i, page: args[:page].to_i)

            return unless st_client.success?

            run_at = Time.current

            client_api_integration.client.contacts.select('contacts.id AS id, ext_references.ext_id AS ext_id').joins(:ext_references).where(ext_references: { target: 'servicetitan', ext_id: st_membership_models.pluck(:customerId) }).includes(:ext_references).find_each do |contact|
              next if (contact_st_membership_models = st_membership_models.select { |stmm| stmm[:customerId] == contact.ext_id.to_i }&.map { |st_membership_model| st_membership_model.merge({ memo: st_membership_model[:memo]&.gsub(%r{[^[:alnum:][:space:][:punct:]]}, '') }) }).blank?

              Integrations::Servicetitan::V2::Memberships::EventsByContactJob.set(wait_until: run_at).perform_later(
                client_id:            client_api_integration.client_id,
                contact_id:           contact.id,
                st_membership_models: contact_st_membership_models
              )

              run_at += 5.seconds
            end
          end
        end
      end
    end
  end
end
