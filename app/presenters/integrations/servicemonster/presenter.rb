# frozen_string_literal: true

# app/presenters/integrations/servicemonster/presenter.rb
module Integrations
  module Servicemonster
    # variables required by ServiceMonster views
    class Presenter
      attr_accessor :webhooks
      attr_reader   :client, :client_api_integration, :webhook, :webhook_event, :webhook_event_id, :webhook_events, :webhook_object

      # :webhook_object example
      # order_OnCreated

      # :webhook example
      # {
      #   order_OnCreated: [
      #     {
      #       actions: {
      #         tag_id: Integer,
      #         group_id: Integer,
      #         stage_id: Integer,
      #         assign_user: Boolean,
      #         campaign_id: Integer
      #       },
      #       criteria: {
      #         event_new: boolean,
      #         order_type: String,
      #         event_updated: boolean
      #       },
      #       event_id: "e29dfaa2-eb61-48f1-a249-f5d594c50242",
      #       line_items: []
      #     }, ...
      #   ]
      # }

      # :webhook_events example
      # [
      #   {
      #     actions: {
      #       tag_id: Integer,
      #       group_id: Integer,
      #       stage_id: Integer,
      #       assign_user: Boolean,
      #       campaign_id: Integer
      #     },
      #     criteria: {
      #       event_new: boolean,
      #       order_type: String,
      #       event_updated: boolean
      #     },
      #     event_id: "e29dfaa2-eb61-48f1-a249-f5d594c50242",
      #     line_items: []
      #   }, ...
      # ]

      # :webhook_event example
      # {
      #   :actions: {
      #     :tag_id: Integer,
      #     :group_id: Integer,
      #     :stage_id: Integer,
      #     :assign_user: Boolean,
      #     :campaign_id: Integer
      #   },
      #   :criteria: {
      #     :event_new: Boolean,
      #     :order_type: String,
      #     :event_updated: Boolean
      #   },
      #   :event_id: "158db8de-3a3f-4c2e-a85e-603df6ae6391",
      #   :line_items: []
      # }

      def initialize(args = {})
        self.client_api_integration = args.dig(:client_api_integration)
      end

      def account_subtypes_for_select
        self.client_api_integration.account_subtypes || []
      end

      def account_types_for_select
        self.client_api_integration.account_types || []
      end

      def appointment_status_for_select
        [
          %w[Unscheduled unscheduled],
          %w[Scheduled scheduled],
          %w[Confirmed confirmed],
          ['On The Job', 'on the job'],
          %w[Complete complete],
          %w[Cancelled cancelled]
        ]
      end

      def campaigns_allowed?
        @client.campaigns_count.positive?
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration)
                                  else
                                    ClientApiIntegration.new
                                  end

        @client                    = @client_api_integration.client
        @job_imports_remaining     = nil
        @servicemonster_client     = nil
        @servicemonster_employees  = nil
        @servicemonster_line_items = nil
        @servicemonster_webhooks   = nil
        @webhook                   = nil
        @webhook_event             = nil
        @webhook_event_id          = nil
        @webhook_events            = []
        @webhook_object            = ''
        @webhooks                  = @client_api_integration.webhooks.deep_symbolize_keys
      end

      def contact_imports_remaining
        Integration::Servicemonster.contact_imports_remaining_string(@client.id)
      end

      def ext_tech_options_for_select
        self.servicemonster_employees.map { |t| [t.dig(:name).to_s, t.dig(:id)] }
      end

      def form_webhook_event_id_hidden_field
        self.webhook.present? ? '' : self.webhook_event_id
      end

      def form_method
        self.webhook.present? ? :patch : :post
      end

      def form_url
        self.webhook.present? ? Rails.application.routes.url_helpers.integrations_servicemonster_webhook_path(self.webhook_event_id) : Rails.application.routes.url_helpers.integrations_servicemonster_webhooks_path
      end

      def groups_allowed?
        @client.groups_count.positive?
      end

      def job_imports_remaining
        @job_imports_remaining ||= Integration::Servicemonster.job_imports_remaining_string(@client.id)
      end

      def job_types_for_select
        (self.client_api_integration.job_types || []) | ['Work', 'Estimate', 'Rework', 'Other', 'Drop Off', 'Pick Up']
      end

      def order_groups_for_select
        self.client_api_integration.order_groups || []
      end

      def order_subgroups_for_select
        self.client_api_integration.order_subgroups || []
      end

      def order_type_for_select
        [
          %w[Estimate estimate],
          ['Work Order', 'order'],
          %w[Invoice invoice]
        ]
      end

      def price_book_grouped_for_select
        response = {}
        self.servicemonster_line_items.map { |li| li.dig(:itemGroup).to_s }.uniq.each { |c| response[c] = [] }
        self.servicemonster_line_items.each { |li| response[li.dig(:itemGroup).to_s] << [li.dig(:name).to_s, li.dig(:itemID).to_s] }

        response
      end

      def push_leads_customer_tag
        Tag.find_by(client_id: @client.id, id: self.client_api_integration.push_leads_tag_id)
      end

      def push_leads_legend_string_customer
        'Tag to Push Contact to ServiceMonster'
      end

      def servicemonster_client
        @servicemonster_client ||= Integrations::ServiceMonster.new(@client_api_integration.credentials)
      end

      def servicemonster_employees
        @servicemonster_employees ||= self.servicemonster_client.employees.map { |e| { id: e.dig(:employeeID), name: Friendly.new.fullname(e.dig(:firstName).to_s, e.dig(:lastName).to_s) } }
      end

      def servicemonster_line_items
        @servicemonster_line_items ||= self.servicemonster_client.line_items.map { |e| { itemID: e.dig(:itemID).to_s, name: e.dig(:name).to_s, itemGroup: e.dig(:itemGroup).to_s } }
      end

      def servicemonster_webhooks
        @servicemonster_webhooks ||= self.servicemonster_client.webhooks
      end

      def stages_allowed?
        @client.stages_count.positive?
      end

      def webhook_event_commercial?
        self.webhook_event&.dig(:criteria, :commercial)&.to_bool
      end

      def webhook_event=(webhook_event)
        @webhook_event    = webhook_event&.deep_symbolize_keys
        @webhook_event_id = @webhook_event&.dig(:id).to_s
        @webhook          = Integration::Servicemonster.webhook_by_event_id(self.client_api_integration.webhooks, @webhook_event_id)
        @webhook_events   = @webhook&.values&.first&.dig(:events)
        @webhook_object   = @webhook&.keys&.first&.to_s
      end

      def webhook_event_account_subtypes
        self.webhook_event&.dig(:criteria, :account_subtypes) || []
      end

      def webhook_event_account_types
        self.webhook_event&.dig(:criteria, :account_types) || []
      end

      def webhook_event_active?
        self.servicemonster_webhooks.find { |w| w.dig(:targetURL).to_s.include?(self.webhook&.values&.first&.dig(:id).to_s) }&.dig(:active)&.to_bool
      end

      def webhook_event_appointment_status
        (self.webhook_event&.dig(:criteria, :appointment_status) || 'unscheduled').to_s
      end

      def webhook_event_campaign
        id = self.webhook_event&.dig(:actions, :campaign_id).to_i
        id.positive? ? Campaign.find_by(client_id: @client.id, id:) : nil
      end

      def webhook_event_ext_tech_ids
        self.webhook_event&.dig(:criteria, :ext_tech_ids) || []
      end

      def webhook_event_group
        id = self.webhook_event&.dig(:actions, :group_id).to_i
        id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
      end

      def webhook_event_job_types
        self.webhook_event&.dig(:criteria, :job_types) || []
      end

      def webhook_event_lead_sources
        self.webhook_event&.dig(:criteria, :lead_sources) || []
      end

      def webhook_event_line_items
        self.webhook_event&.dig(:criteria, :line_items) || []
      end

      def webhook_event_line_item_names
        self.webhook_event_line_items.filter_map { |l| self.servicemonster_line_items.find { |i| i.dig(:itemID) == l }&.dig(:name) }.compact_blank.join(', ')
      end

      def webhook_event_new
        (self.webhook_event&.dig(:criteria, :event_new) || false).to_bool
      end

      def webhook_event_order_groups
        self.webhook_event&.dig(:criteria, :order_groups) || []
      end

      def webhook_event_order_subgroups
        self.webhook_event&.dig(:criteria, :order_subgroups) || []
      end

      def webhook_event_order_type
        self.webhook_event&.dig(:criteria, :order_type).to_s
      end

      def webhook_event_order_type_voided?
        self.webhook_event&.dig(:criteria, :order_type_voided)&.to_bool
      end

      def webhook_event_range_max
        (self.webhook_event&.dig(:criteria, :range_max) || 10_000).to_i
      end

      def webhook_event_residential?
        self.webhook_event&.dig(:criteria, :residential)&.to_bool
      end

      def webhook_event_stage
        id = self.webhook_event&.dig(:actions, :stage_id).to_i
        id.positive? ? Stage.for_client(@client.id).find_by(id:) : nil
      end

      def webhook_event_start_date_updated
        (self.webhook_event&.dig(:criteria, :start_date_updated) || false).to_bool
      end

      def webhook_event_status_updated
        (self.webhook_event&.dig(:criteria, :status_updated) || false).to_bool
      end

      def webhook_event_stop_campaigns
        return ['All Campaigns'] if self.webhook_event_stop_campaign_ids&.include?(0)

        Campaign.where(client_id: self.client_api_integration.client_id, id: self.webhook_event_stop_campaign_ids).pluck(:name)
      end

      def webhook_event_stop_campaign_ids
        self.webhook_event&.dig(:actions, :stop_campaign_ids)&.compact_blank
      end

      def webhook_event_tag
        id = self.webhook_event&.dig(:actions, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
      end

      def webhook_event_tech_updated
        (self.webhook_event&.dig(:criteria, :tech_updated) || false).to_bool
      end

      def webhook_event_total_max
        (self.webhook_event&.dig(:criteria, :total_max) || self.webhook_event_range_max).to_i
      end

      def webhook_event_total_min
        (self.webhook_event&.dig(:criteria, :total_min) || 0).to_i
      end

      def webhook_event_updated
        (self.webhook_event&.dig(:criteria, :event_updated) || false).to_bool
      end

      def webhook_events_array
        Integration::Servicemonster.webhooks.map { |w| [w.dig(:name).to_s, w.dig(:event).to_s] }
      end

      def webhook_events_count
        webhook_events = 0

        self.client_api_integration.webhooks.each { |webhook| webhook.last.dig('events').each { |_event| webhook_events += 1 } }

        webhook_events
      end

      def webhook_name
        (Integration::Servicemonster.webhooks.find { |w| w[:event] == self.webhook_object } || { name: 'unknown' }).dig(:name).to_s
      end

      def webhook_name_with_type
        "#{self.webhook_name}#{if self.webhook_event_order_type.present?
                                 " (#{self.webhook_event_order_type.titleize}#{self.webhook_event_order_type_voided? ? ' Voided' : ''})"
                               else
                                 ''
                               end}"
      end
    end
  end
end
