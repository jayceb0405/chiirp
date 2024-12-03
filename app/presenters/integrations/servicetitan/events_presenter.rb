# frozen_string_literal: true

# app/presenters/integrations/servicetitan/events_presenter.rb
module Integrations
  module Servicetitan
    class EventsPresenter
      attr_accessor :event
      attr_reader   :api_key, :client, :client_api_integration

      # Integrations::Servicetitan::EventsPresenter.new()
      # client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration)
        self.client_api_integration = client_api_integration
      end

      def actions
        @client_api_integration.events
      end

      def assign_contact_to_user
        @event&.second&.dig('assign_contact_to_user')&.to_bool
      end

      def business_unit_ids
        @event&.second&.dig('business_unit_ids') || []
      end

      def business_units_for_select
        @st_model.business_units
      end

      def business_units_string
        @st_model.business_units(raw: true).select { |x| self.business_unit_ids.include?(x[:id]) }.map { |bu| bu[:name].strip }.join(' or ')
      end

      def call_directions
        @event&.second&.dig('call_directions') || []
      end

      def call_duration_from
        @event&.second&.dig('call_duration_from') || 0
      end

      def call_duration_to
        @event&.second&.dig('call_duration') || @event&.second&.dig('call_duration_to') || 0
      end

      def call_event_delay
        @client_api_integration.call_event_delay.to_i
      end

      def call_reason_ids
        @event&.second&.dig('call_reason_ids') || []
      end

      def call_reasons
        @st_model.call_reasons
      end

      def call_types
        @event&.second&.dig('call_types') || []
      end

      def campaign_ids
        @event&.second&.dig('campaign_ids') || []
      end

      def campaign
        campaign_id.positive? ? Campaign.find_by(client_id: @client.id, id: campaign_id) : nil
      end

      def campaign_id
        @event&.second&.dig('campaign_id').to_i
      end

      def campaign_name_contains
        @event&.second&.dig('campaign_name', 'contains')&.to_bool
      end

      def campaign_name_end
        @event&.second&.dig('campaign_name', 'end')&.to_bool
      end

      def campaign_name_segment
        @event&.second&.dig('campaign_name', 'segment').to_s
      end

      def campaign_name_start
        @event&.second&.dig('campaign_name', 'start')&.to_bool
      end

      def campaigns_allowed
        @client.campaigns_count.positive?
      end

      def campaigns_for_select
        @st_model.campaigns
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration = case client_api_integration
                                  when ClientApiIntegration
                                    client_api_integration
                                  when Integer
                                    ClientApiIntegration.find_by(id: client_api_integration, target: 'servicetitan')
                                  else
                                    ClientApiIntegration.new(target: 'servicetitan')
                                  end

        @st_model = Integration::Servicetitan::V2::Base.new(@client_api_integration)

        @api_key                           = @client_api_integration.api_key
        @categories                        = nil
        @client                            = @client_api_integration.client
        @client_api_integration_line_items = nil
        @credentials                       = self.credentials
        @event                             = nil
        @tag_collection_options            = nil

        @st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
      end

      def client_api_integration_line_items
        @client_api_integration_line_items ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'line_items')
      end

      def credentials
        @st_model.valid_credentials? ? @client_api_integration.credentials : {}
      end

      def customer_type
        @event&.second&.dig('customer_type')
      end

      def customer_type_string
        self.customer_type.map(&:titleize).join(' or ')
      end

      def employees_for_select
        self.servicetitan_employees.map { |e| [e[:name], e[:id]] }
      end

      def ext_tech_ids
        @event&.second&.dig('ext_tech_ids') || []
      end

      def ext_tech_ids_for_select
        @ext_tech_collection_options || @st_model.technicians(for_select: true) || []
      end

      def event_id
        @event&.first.to_i
      end

      def event_type
        @event&.second&.dig('action_type').to_s
      end

      def event_type_string
        self.event_type.tr('_', ' ').titleize
      end

      def group
        @client.groups.find_by(id: group_id) || @client.groups.new
      end

      def group_id
        @event&.second&.dig('group_id').to_i
      end

      def groups_allowed
        @client.groups_count.positive?
      end

      def ignore_sold_with_line_items
        self.client_api_integration.ignore_sold_with_line_items
      end

      def job_cancel_reason_ids
        @event&.second&.dig('job_cancel_reason_ids') || []
      end

      def job_cancel_reasons
        @st_model.job_cancel_reasons
      end

      def job_types
        @event&.second&.dig('job_types') || []
      end

      def job_types_string
        @event&.second&.dig('job_types')&.map { |job_type_id| self.servicetitan_job_types.find { |job_type| job_type[1].to_i == job_type_id.to_i } || '' }&.compact_blank&.map(&:first)&.join(' or ')
      end

      def line_item_categories
        self.client_api_integration_line_items.categories
      end

      def line_item_type_equipment
        self.client_api_integration_line_items.equipment
      end

      def line_item_type_materials
        self.client_api_integration_line_items.materials
      end

      def line_item_type_services
        self.client_api_integration_line_items.services
      end

      def membership
        @event&.second&.dig('membership')
      end

      def membership_campaign_stop_statuses
        @event&.second&.dig('membership_campaign_stop_statuses')
      end

      def membership_days_prior
        @event&.second&.dig('membership_days_prior') || 90
      end

      def membership_types
        @event&.second&.dig('membership_types') || []
      end

      def membership_type_label
        event_type == 'membership_expiration' ? 'ServiceTitan Memberships (Trigger)' : 'ServiceTitan Memberships'
      end

      def membership_types_stop
        @event&.second&.dig('membership_types_stop') || []
      end

      def membership_types_select
        @st_model.membership_types
      end

      def membership_statuses_for_select
        [
          ['Not Attempted', 'NotAttempted'],
          %w[Unreachable],
          %w[Contacted],
          %w[Won],
          %w[Dismissed]
        ]
      end

      def membership_string
        self.membership.map(&:titleize).join(' or ')
      end

      def new_status
        @event&.second&.dig('new_status')
      end

      def options_for_line_items
        self.client_api_integration_line_items.line_items
      end

      def options_for_line_item_categories
        @categories ||= @st_model.pricebook_categories(raw: true)
        @categories.sort_by { |c| c.dig(:name) }.map { |c| [c.dig(:name), c.dig(:subcategories).sort_by { |c| c.dig(:name).to_s }.map { |sc| [sc.dig(:name), sc.dig(:id)] }] if c.dig(:subcategories).present? }.compact_blank
      end

      def orphaned_estimates?
        @event&.second&.dig('orphaned_estimates')&.to_bool
      end

      def range_max
        (@event&.second&.dig('range_max') || 1_000).to_i
      end

      def reviews
        @client_api_integration.reviews
      end

      def reviews_tag_id_0_star
        self.reviews['tag_id_0_star']
      end

      def reviews_tag_id_1_star
        self.reviews['tag_id_1_star']
      end

      def reviews_tag_id_2_star
        self.reviews['tag_id_2_star']
      end

      def reviews_tag_id_3_star
        self.reviews['tag_id_3_star']
      end

      def reviews_tag_id_4_star
        self.reviews['tag_id_4_star']
      end

      def reviews_tag_id_5_star
        self.reviews['tag_id_5_star']
      end

      def servicetitan_job_types
        @servicetitan_job_types ||= @st_model.job_types
      end

      def show_status_in_index?
        @event&.second&.dig('action_type').to_s == 'estimate'
      end

      def show_totals_in_index?
        (self.event_type == 'estimate' && self.status == 'sold') || self.event_type == 'job_complete'
      end

      def sorted_events
        self.actions.sort_by { |_key, value| [value['action_type'], value['total_min'].to_d, value['customer_type'].to_s, value['status'].to_s, value['business_unit_ids'].to_s, value['membership'].to_s] }
      end

      def st_customer_no
        @event&.second&.dig('st_customer', 'no')&.to_bool
      end

      def st_customer_yes
        @event&.second&.dig('st_customer', 'yes')&.to_bool
      end

      def stage
        stage_id.positive? ? Stage.for_client(@client.id).find_by(id: stage_id) : nil
      end

      def stage_id
        @event&.second&.dig('stage_id').to_i
      end

      def stages_allowed
        @client.stages_count.positive?
      end

      def start_date_changes_only
        @event&.second&.dig('start_date_changes_only')&.to_bool
      end

      def status
        @event&.second&.dig('status').to_s
      end

      def status_string
        self.status.titleize
      end

      def stop_campaign_ids
        @event&.second&.dig('stop_campaign_ids').presence || []
      end

      def tag
        @client.tags.find_by(id: self.tag_id) || @client.tags.new
      end

      def tag_collection_options
        @tag_collection_options || @client.tag_collection_options(false, [])
      end

      def tag_id
        @event&.second&.dig('tag_id').to_i
      end

      def tag_ids_exclude
        @event&.second&.dig('tag_ids_exclude') || []
      end

      def tag_ids_include
        @event&.second&.dig('tag_ids_include') || []
      end

      def tags_for_select
        @st_model.tag_types
      end

      def total_max
        (@event&.second&.dig('total_max') || self.range_max).to_i
      end

      def total_min
        (@event&.second&.dig('total_min') || 0).to_i
      end

      def update_review_window_hours
        self.reviews['update_review_window_hours']
      end
    end
  end
end
