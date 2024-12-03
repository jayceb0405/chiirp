# frozen_string_literal: true

# app/presenters/integrations/jobnimbus/presenter.rb
module Integrations
  module Jobnimbus
    # variables required by JobNimbus views
    class Presenter < BasePresenter
      attr_accessor :webhooks
      attr_reader   :client, :client_api_integration, :webhook, :webhook_event, :webhook_event_id, :webhook_events, :webhook_object

      # Integrations::Jobnimbus::Presenter.new(client_api_integration: ClientApiIntegration)
      def initialize(args = {})
        super

        @jn_model = Integration::Jobnimbus::V1::Base.new(@client_api_integration)
      end

      def contact_imports_remaining
        Integration::Jobnimbus::V1::Base.new(@client_api_integration).contact_imports_remaining_string
      end

      def contact_status_options_array
        (@jn_model.contact_status_list + ['Lead', 'Appointment Scheduled', 'No Damage', 'Estimating', 'Pending Customer Signature', 'Signed Contract',
                                          'Contract Review', 'Additional Info Needed', 'Job Approval', 'Pull Permit', 'Order/Schedule Job', 'Pending Start Date',
                                          'Jobs In Progress', 'Other Trades Pending', 'Job Completed', 'Invoicing', 'Pending Payments', 'Paid & Closed', 'Lost']).uniq.sort
      end

      def estimate_status_options_array
        (@jn_model.estimate_status_list + %w[Draft Sent Denied Approved Invoiced Void]).uniq.sort
      end

      def fail_html
        '<i class="text-danger fa fa-times"></i>'.html_safe
      end

      def form_method
        @webhook_event_id.present? ? :patch : :post
      end

      def form_url
        @webhook_event_id.present? ? Rails.application.routes.url_helpers.integrations_jobnimbus_webhook_path(@webhook_event_id) : Rails.application.routes.url_helpers.integrations_jobnimbus_webhooks_path
      end

      def invoice_status_options_array
        (@jn_model.invoice_status_list + %w[Draft Sent Open Closed Cancelled Void]).uniq.sort
      end

      def job_status_options_array
        (@jn_model.job_status_list + ['Follow Up 1', 'Appointment Scheduled', 'Scheduled', 'Pending Payments', 'Pending Sync QB']).uniq.sort
      end

      def push_leads_customer_tag
        Tag.find_by(client_id: @client.id, id: @client_api_integration.push_contacts_tag_id)
      end

      def push_leads_legend_string_customer
        'Tag to Push Contact to JobNimbus'
      end

      def success_html
        '<i class="text-success fa fa-check"></i>'.html_safe
      end

      def webhook_event=(webhook_event)
        @webhook_event    = webhook_event&.deep_symbolize_keys
        @webhook_event_id = @webhook_event&.dig(:event_id).to_s
        @webhook          = Integration::Jobnimbus::V1::Base.new(@client_api_integration).webhook_by_id(@webhook_event_id)
        @webhook_events   = @webhook.values.flatten
        @webhook_object   = @webhook.keys.first.to_s
      end

      def task_types_for_select
        @jn_model.task_type_list
      end

      def webhook_event_campaign
        id = @webhook_event.dig(:actions, :campaign_id).to_i
        id.positive? ? Campaign.find_by(client_id: @client_api_integration.client_id, id:) : nil
      end

      def webhook_event_group
        id = @webhook_event.dig(:actions, :group_id).to_i
        id.positive? ? Group.find_by(client_id: @client_api_integration.client_id, id:) : nil
      end

      def webhook_event_new
        (@webhook_event.dig(:criteria, :event_new) || false).to_bool
      end

      def webhook_event_new_icon
        webhook_event_new ? success_html : fail_html
      end

      def webhook_event_stage
        id = @webhook_event.dig(:actions, :stage_id).to_i
        id.positive? ? Stage.for_client(@client_api_integration.client_id).find_by(id:) : nil
      end

      def webhook_event_stop_campaigns
        return ['All Campaigns'] if @webhook_event_stop_campaign_ids&.include?(0)

        Campaign.where(client_id: @client.id, id: @webhook_event_stop_campaign_ids).pluck(:name)
      end

      def webhook_event_stop_campaign_ids
        @webhook_event.dig(:actions, :stop_campaign_ids)&.compact_blank
      end

      def webhook_event_tag
        id = @webhook_event.dig(:actions, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: @client_api_integration.client_id, id:) : nil
      end

      def webhook_event_task_types
        @webhook_event&.dig(:criteria, :task_types) || []
      end

      def webhook_event_updated
        (@webhook_event.dig(:criteria, :event_updated) || false).to_bool
      end

      def webhook_event_updated_icon
        webhook_event_updated ? success_html : fail_html
      end

      def webhook_events_array
        Integration::Jobnimbus::V1::Base::WEBHOOKS.map { |w| [w.dig(:name).to_s, w.dig(:event).to_s] }
      end

      def webhook_events_count
        webhook_events = 0

        @client_api_integration.webhooks.each { |_webhook, events| webhook_events += events.length }

        webhook_events
      end

      def webhook_name
        (Integration::Jobnimbus::V1::Base::WEBHOOKS.find { |w| w[:event] == @webhook_object } || { name: 'unknown' }).dig(:name).to_s
      end

      def workorder_status_options_array
        (@jn_model.workorder_status_list + ['Assigned', 'In Progress', 'Completed']).uniq.sort
      end

      def webhook_task_status
        @webhook_event.dig(:criteria, :status).to_s.casecmp?('completed')
      end
    end
  end
end
