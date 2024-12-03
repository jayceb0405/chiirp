# frozen_string_literal: true

# app/presenters/integrations/housecall/presenter.rb
module Integrations
  module Housecall
    class Presenter < BasePresenter
      attr_reader   :event, :event_name, :events, :webhook, :webhooks, :webhook_id

      def campaigns_allowed
        @client.campaigns_count.positive?
      end

      def client_api_integration=(client_api_integration)
        super
        @event                  = nil
        @event_name             = ''
        @events                 = []
        @hcp_client             = Integrations::HousecallPro::Base.new(@client_api_integration.credentials)
        @hcp_model              = Integration::Housecallpro::V1::Base.new(@client_api_integration)
        @housecallpro_employees = nil
        @job_imports_remaining  = nil
        @webhook                = nil
        @webhook_id             = nil
        @webhooks               = @client_api_integration.webhooks&.deep_symbolize_keys || []
      end

      def contact_imports_remaining
        @hcp_model.contact_imports_remaining_string
      end

      def estimate_approval_status_options
        [%w[Approved approved], ['Pro Approved', 'pro approved'], %w[Declined declined], ['Pro Declined', 'pro declined'], ['No Status Selected', 'null']]
      end

      def estimate_imports_remaining
        @estimate_imports_remaining ||= @hcp_model.estimate_imports_remaining_string
      end

      def event=(event)
        @event      = event
        @event_name = @event[0].to_s
        @events     = @event[1]
      end

      def ext_tech_options_for_select
        self.housecallpro_employees.map { |t| [t.dig(:name).to_s, t.dig(:id)] }
      end

      def form_method
        self.webhook_id.present? ? :patch : :post
      end

      def form_url
        self.webhook_id.present? ? Rails.application.routes.url_helpers.integrations_housecall_webhook_path(self.webhook_id, event: self.event_name) : Rails.application.routes.url_helpers.integrations_housecall_webhooks_path
      end

      def groups_allowed
        @client.groups_count.positive?
      end

      def housecallpro_employees
        @housecallpro_employees ||= @hcp_model.technicians.map { |e| { id: e.dig(:id), name: Friendly.new.fullname(e.dig(:firstname), e.dig(:lastname)) } }
      end

      def job_imports_remaining
        @job_imports_remaining ||= @hcp_model.job_imports_remaining_string
      end

      def options_for_status
        [
          %w[Unscheduled unscheduled],
          %w[Scheduled scheduled],
          ['In Progress', 'in_progress'],
          %w[Completed completed],
          %w[Cancelled canceled]
        ]
      end

      def overview_api_key_icon
        @hcp_model.valid_credentials? ? '<i class="fa fa-link text-success"></i>' : '<i class="fa fa-link text-danger"></i>'
      end

      def overview_api_key_title
        @hcp_model.valid_credentials? ? 'Connected' : 'Not Connected'
      end

      def price_book_grouped_for_select
        response = {}
        @client_api_integration.price_book.values.pluck('category').uniq.compact_blank.each { |category| response[category] = [] }
        @client_api_integration.price_book.each { |key, value| response[value['category']] << [value['name'], key] if value['category'].present? }

        response
      end

      def push_leads_customer_tag
        Tag.find_by(client_id: @client.id, id: @client_api_integration.push_leads_tag_id)
      end

      def push_leads_legend_string_customer
        'Tag to Push Contact to Housecall Pro'
      end

      def stages_allowed
        @client.stages_count.positive?
      end

      def valid_credentials?
        @hcp_model.valid_credentials?
      end

      def webhook=(webhook)
        @webhook    = webhook&.deep_symbolize_keys || {}
        @webhook_id = @webhook&.dig(:event_id).to_s
      end

      def webhook_active
        self.webhook.dig(:active).nil? ? true : self.webhook[:active]
      end

      def webhook_approval_status
        self.webhook.dig(:criteria, :approval_status)
      end

      def webhook_campaign
        id = self.webhook.dig(:actions, :campaign_id).to_i
        id.positive? ? Campaign.find_by(client_id: @client.id, id:) : nil
      end

      def webhook_event_lead_sources
        self.webhook.dig(:criteria, :lead_sources) || []
      end

      def webhook_event_new
        (self.webhook.dig(:criteria, :event_new) || false).to_bool
      end

      def webhook_event_updated
        (self.webhook.dig(:criteria, :event_updated) || false).to_bool
      end

      def webhook_events_array
        Integration::Housecallpro::V1::Base::WEBHOOK_EVENTS.map { |webhook| [webhook[:name].titleize, webhook[:event].tr('.', '_')] }
      end

      def webhook_ext_tech_ids
        self.webhook.dig(:criteria, :ext_tech_ids) || []
      end

      def webhook_group
        id = self.webhook.dig(:actions, :group_id).to_i
        id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
      end

      def webhook_line_items
        self.webhook.dig(:criteria, :line_items) || []
      end

      def webhook_line_item_names
        self.webhook_line_items.map { |line_item| @client_api_integration.price_book.dig(line_item)&.dig('name') }.compact_blank.join(', ')
      end

      def webhook_name
        (Integration::Housecallpro::V1::Base::WEBHOOK_EVENTS.find { |event| event[:event].tr('.', '_') == self.event_name } || { name: 'unknown' }).dig(:name).to_s.titleize
      end

      def webhook_stage
        id = self.webhook.dig(:actions, :stage_id).to_i
        id.positive? ? Stage.for_client(@client.id).find_by(id:) : nil
      end

      def webhook_start_date_updated
        (self.webhook.dig(:criteria, :start_date_updated) || false).to_bool
      end

      def webhook_stop_campaign_ids
        self.webhook.dig(:actions, :stop_campaign_ids)
      end

      def webhook_stop_campaigns
        return ['All Campaigns'] if self.webhook.dig(:actions, :stop_campaign_ids)&.include?(0)

        Campaign.where(client_id: @client.id, id: self.webhook.dig(:actions, :stop_campaign_ids)).pluck(:name)
      end

      def webhook_tag
        id = self.webhook.dig(:actions, :tag_id).to_i
        id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
      end

      def webhook_tech_updated
        (self.webhook.dig(:criteria, :tech_updated) || false).to_bool
      end

      def webhook_status_updated
        (self.webhook.dig(:criteria, :status_updated) || false).to_bool
      end
    end
  end
end
