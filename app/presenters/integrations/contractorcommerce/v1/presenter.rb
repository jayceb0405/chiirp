# frozen_string_literal: true

# app/presenters/integrations/contractorcommerce/v1/presenter.rb
module Integrations
  module Contractorcommerce
    module V1
      class Presenter < BasePresenter
        attr_reader :event, :event_type, :events, :event_id

        def campaigns_allowed
          @client.campaigns_count.positive?
        end

        def client_api_integration=(client_api_integration)
          super
          @event      = nil
          @event_id   = nil
          @event_type = ''
          @events     = @client_api_integration.events&.map(&:deep_symbolize_keys) || []
        end

        def event=(event)
          @event      = event
          @event_id   = @event.dig(:event_id).to_s
          @event_type = @event.dig(:event_type)
        end

        def event_campaign
          id = @event.dig(:actions, :campaign_id).to_i
          id.positive? ? Campaign.find_by(client_id: @client.id, id:) : nil
        end

        def event_group
          id = @event.dig(:actions, :group_id).to_i
          id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
        end

        def event_lead_types
          @event.dig(:criteria, :lead_types) || []
        end

        def event_new
          (@event.dig(:criteria, :event_new) || false).to_bool
        end

        def event_stage
          id = @event.dig(:actions, :stage_id).to_i
          id.positive? ? Stage.for_client(@client.id).find_by(id:) : nil
        end

        def event_start_date_updated
          (@event.dig(:criteria, :start_date_updated) || false).to_bool
        end

        def event_status
          @event.dig(:criteria, :status) || []
        end

        def event_stop_campaigns
          return ['All Campaigns'] if @event.dig(:actions, :stop_campaign_ids)&.include?(0)

          Campaign.where(client_id: @client.id, id: @event.dig(:actions, :stop_campaign_ids)).pluck(:name)
        end

        def event_stop_campaign_ids
          @event.dig(:actions, :stop_campaign_ids) || []
        end

        def event_tag
          id = @event.dig(:actions, :tag_id).to_i
          id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
        end

        def event_types_array
          []
        end

        def event_updated
          (@event.dig(:criteria, :event_updated) || false).to_bool
        end

        def form_method
          @event_id.present? ? :patch : :post
        end

        def form_url
          @event_id.present? ? Rails.application.routes.url_helpers.integrations_contractorcommerce_v1_event_path(@event_id) : Rails.application.routes.url_helpers.integrations_contractorcommerce_v1_events_path
        end

        def groups_allowed
          @client.groups_count.positive?
        end

        def stages_allowed
          @client.stages_count.positive?
        end

        def status_for_select(event_type = @event_type)
          []
        end

        # verify that Contractor Commerce credentials are valid
        # presenter.valid_credentials?
        def valid_credentials?
          Integration::Contractorcommerce::V1::Base.new(@client_api_integration).valid_credentials?
        end
      end
    end
  end
end
