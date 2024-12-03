# frozen_string_literal: true

# app/jobs/integrations/servicetitan/v2/customers/balance/balance_actions_job.rb
module Integrations
  module Servicetitan
    module V2
      module Customers
        module Balance
          class BalanceActionsJob < ApplicationJob
            # description of this job
            # Integrations::Servicetitan::V2::Customers::Balance::BalanceActionsJob.perform_now()
            # Integrations::Servicetitan::V2::Customers::Balance::BalanceActionsJob.set(wait_until: 1.day.from_now).perform_later()
            # Integrations::Servicetitan::V2::Customers::Balance::BalanceActionsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later(
            def initialize(**args)
              super

              @process = (args.dig(:process).presence || 'servicetitan_customers_balance_actions').to_s
            end

            # perform the ActiveJob
            #   (req) client_id:                (Integer)
            #   (req) contact_id:               (Integer)
            #   (req) previous_account_balance: (BigDecimal)
            #   (req) current_account_balance:  (BigDecimal)
            def perform(**args)
              super

              return unless Integer(args.dig(:client_id), exception: false).present? && Integer(args.dig(:contact_id), exception: false).present? &&
                            BigDecimal(args.dig(:previous_account_balance), exception: false).present? && BigDecimal(args.dig(:current_account_balance), exception: false).present? &&
                            args.dig(:previous_account_balance).to_d != args.dig(:current_account_balance).to_d &&
                            (contact = Contact.find_by(id: args[:contact_id].to_i, client_id: args[:client_id].to_i)) &&
                            (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id].to_i, target: 'servicetitan', name: ''))

              update_balance_actions = client_api_integration.update_balance_actions.symbolize_keys

              if args.dig(:current_account_balance).to_d.zero? && args.dig(:previous_account_balance).to_d.positive?
                campaign_id       = update_balance_actions[:campaign_id_0].to_i
                group_id          = update_balance_actions[:group_id_0].to_i
                stage_id          = update_balance_actions[:stage_id_0].to_i
                tag_id            = update_balance_actions[:tag_id_0].to_i
                stop_campaign_ids = Array(update_balance_actions[:stop_campaign_ids_0]).map(&:to_i)
              elsif args.dig(:current_account_balance).to_d.positive? && args.dig(:current_account_balance).to_d > args.dig(:previous_account_balance).to_d
                campaign_id       = update_balance_actions[:campaign_id_increase].to_i
                group_id          = update_balance_actions[:group_id_increase].to_i
                stage_id          = update_balance_actions[:stage_id_increase].to_i
                tag_id            = update_balance_actions[:tag_id_increase].to_i
                stop_campaign_ids = Array(update_balance_actions[:stop_campaign_ids_increase]).map(&:to_i)
              elsif args.dig(:current_account_balance).to_d.positive? && args.dig(:current_account_balance).to_d < args.dig(:previous_account_balance).to_d
                campaign_id       = update_balance_actions[:campaign_id_decrease].to_i
                group_id          = update_balance_actions[:group_id_decrease].to_i
                stage_id          = update_balance_actions[:stage_id_decrease].to_i
                tag_id            = update_balance_actions[:tag_id_decrease].to_i
                stop_campaign_ids = Array(update_balance_actions[:stop_campaign_ids_decrease]).map(&:to_i)
              else
                return
              end

              contact.process_actions(campaign_id:, group_id:, stage_id:, tag_id:, stop_campaign_ids:)
            end
          end
        end
      end
    end
  end
end
