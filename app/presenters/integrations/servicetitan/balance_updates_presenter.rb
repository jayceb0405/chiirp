# frozen_string_literal: true

# app/presenters/integrations/servicetitan/balance_updates_presenter.rb
module Integrations
  module Servicetitan
    class BalanceUpdatesPresenter < Integrations::Servicetitan::Presenter
      # Integrations::Servicetitan::EventsPresenter.new()
      # client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration)
        super

        @group_0        = nil
        @group_decrease = nil
        @group_increase = nil
        @tag_0          = nil
        @tag_decrease   = nil
        @tag_increase   = nil
      end

      def campaign_id_0
        @client_api_integration.update_balance_actions['campaign_id_0'].to_i
      end

      def campaign_id_decrease
        @client_api_integration.update_balance_actions['campaign_id_decrease'].to_i
      end

      def campaign_id_increase
        @client_api_integration.update_balance_actions['campaign_id_increase'].to_i
      end

      def group_0
        @group_0 ||= @client_api_integration.update_balance_actions['group_id_0'].to_i.positive? ? @client_api_integration.client.groups.find_by(id: @client_api_integration.update_balance_actions['group_id_0'].to_i) : @client_api_integration.client.groups.new
      end

      def group_decrease
        @group_decrease ||= @client_api_integration.update_balance_actions['group_id_decrease'].to_i.positive? ? @client_api_integration.client.groups.find_by(id: @client_api_integration.update_balance_actions['group_id_decrease'].to_i) : @client_api_integration.client.groups.new
      end

      def group_increase
        @group_increase ||= @client_api_integration.update_balance_actions['group_id_increase'].to_i.positive? ? @client_api_integration.client.groups.find_by(id: @client_api_integration.update_balance_actions['group_id_increase'].to_i) : @client_api_integration.client.groups.new
      end

      def stop_campaign_ids_0
        @client_api_integration.update_balance_actions['stop_campaign_ids_0']
      end

      def stop_campaign_ids_decrease
        @client_api_integration.update_balance_actions['stop_campaign_ids_decrease']
      end

      def stop_campaign_ids_increase
        @client_api_integration.update_balance_actions['stop_campaign_ids_increase']
      end

      def stage_id_0
        @client_api_integration.update_balance_actions['stage_id_0'].to_i
      end

      def stage_id_decrease
        @client_api_integration.update_balance_actions['stage_id_decrease'].to_i
      end

      def stage_id_increase
        @client_api_integration.update_balance_actions['stage_id_increase'].to_i
      end

      def tag_0
        @tag_0 ||= @client_api_integration.update_balance_actions['tag_id_0'].to_i ? @client_api_integration.client.tags.find_by(id: @client_api_integration.update_balance_actions['tag_id_0'].to_i) : @client_api_integration.client.tags.new
      end

      def tag_decrease
        @tag_decrease ||= @client_api_integration.update_balance_actions['tag_id_decrease'].to_i ? @client_api_integration.client.tags.find_by(id: @client_api_integration.update_balance_actions['tag_id_decrease'].to_i) : @client_api_integration.client.tags.new
      end

      def tag_increase
        @tag_increase ||= @client_api_integration.update_balance_actions['tag_id_increase'].to_i ? @client_api_integration.client.tags.find_by(id: @client_api_integration.update_balance_actions['tag_id_increase'].to_i) : @client_api_integration.client.tags.new
      end

      def update_balance_window_days
        @client_api_integration.update_balance_actions['update_balance_window_days'].to_i
      end

      def update_invoice_window_days
        @client_api_integration.update_balance_actions['update_invoice_window_days'].to_i
      end

      def update_open_estimate_window_days
        @client_api_integration.update_balance_actions['update_open_estimate_window_days'].to_i
      end

      def update_open_job_window_days
        @client_api_integration.update_balance_actions['update_open_job_window_days'].to_i
      end

      def update_open_estimate_window_days_info
        <<-RESP.squish
          <strong>Note:</strong></ br>
          <ul>
          <li>Estimates are checked at 6am and 9pm local time each day.</li>
          </ul>
        RESP
      end

      def update_open_job_window_days_info
        <<-RESP.squish
          <strong>Note:</strong></ br>
          <ul>
          <li>Jobs are checked between 6am and 9pm local time each day.</li>
          <li>Jobs updated within 30 days will be checked every 3 hours (beginning at 6am).</li>
          <li>Jobs updated between 31 & 90 days ago will be checked at 6am, 12pm, 6pm & 9pm.</li>
          <li>Jobs updated between 91 & 180 days ago will be checked at 6am & 9pm.</li>
          <li>Jobs updated between 181 & 365 days ago will be checked at 6am.</li>
          </ul>
        RESP
      end
    end
  end
end
