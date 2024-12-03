# frozen_string_literal: true

# app/presenters/integrations/successware/v202311/presenter.rb
module Integrations
  module Successware
    module V202311
      class Presenter < BasePresenter
        attr_reader :event, :event_name, :events, :webhook, :webhooks, :webhook_id

        # Integrations::Successware::V202311::Presenter.new(client_api_integration: @client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration) or (Integer)

        def campaigns_allowed
          @client.campaigns_count.positive?
        end

        def client_api_integration=(client_api_integration)
          super
          @event                       = nil
          @event_name                  = ''
          @events                      = []
          @sw_client                   = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials)
          @sw_model                    = Integration::Successware::V202311::Base.new(@client_api_integration)
          @successware_employees       = nil
          @products                    = nil
          @products_grouped_for_select = nil
          @ext_tech_options_for_select = nil
          @webhook                     = nil
          @webhook_id                  = nil
          @webhooks                    = @client_api_integration.webhooks&.deep_symbolize_keys || []
        end

        def contact_imports_remaining_string(user_id)
          @sw_model.import_contacts_remaining_string(user_id)
        end

        def customer_type
          @webhook.dig(:criteria, :customer_type) || []
        end

        def event=(event)
          @event      = event
          @event_name = @event[0].to_s
          @events     = @event[1]
        end

        def ext_tech_options_for_select
          @ext_tech_options_for_select ||= @sw_client.users.map { |u| [[u[:firstName], u[:lastName]].join(' '), u[:id]] }
        end

        def form_method
          @webhook_id.present? ? :patch : :post
        end

        def form_url
          @webhook_id.present? ? Rails.application.routes.url_helpers.integrations_successware_v202311_webhook_path(@webhook_id, event: @event_name) : Rails.application.routes.url_helpers.integrations_successware_202311_webhooks_path
        end

        def groups_allowed
          @client.groups_count.positive?
        end

        def job_type
          @webhook.dig(:criteria, :job_type) || []
        end

        def job_types_array
          @sw_model.job_types(grouped: true)
        end

        def successware_employees
          @successware_employees ||= @sw_client.users.sort_by { |u| "#{u.dig(:lastName)}#{u.dig(:firstName)}" }
        end

        def successware_employees_linked
          self.successware_employees.present? ? self.client_api_integration.employees&.values&.delete_if(&:zero?)&.count.to_f / self.successware_employees.length : 0
        end

        def options_for_request_source
          (@client_api_integration.request_sources || []).map { |request_source| [request_source.titleize, request_source] }
        end

        def products
          @products ||= @sw_client.products
        end

        def products_grouped_for_select
          @products_grouped_for_select ||= products.pluck(:category).uniq.compact_blank.sort.map { |c| [c, products.select { |sp| sp[:category] == c }.sort_by { |s| s[:name].downcase }.map { |p| [p[:name], p[:id]] }] }
        end

        def push_leads_customer_tag
          Tag.find_by(client_id: @client.id, id: @client_api_integration.push_contacts_tag_id)
        end

        def push_leads_legend_string_customer
          'Tag to Push Contact to Successware'
        end

        def stages_allowed
          @client.stages_count.positive?
        end

        # verify that Successware credentials are valid
        # presenter.connection_valid?
        def valid_credentials?
          @sw_model.valid_credentials?
        end

        def webhook=(webhook)
          @webhook    = webhook.deep_symbolize_keys
          @webhook_id = @webhook[:event_id]
        end

        def webhook_campaign
          id = @webhook.dig(:actions, :campaign_id).to_i
          id.positive? ? Campaign.find_by(client_id: @client.id, id:) : nil
        end

        def webhook_event_new
          (@webhook.dig(:criteria, :event_new) || false).to_bool
        end

        def webhook_event_updated
          (@webhook.dig(:criteria, :event_updated) || false).to_bool
        end

        def webhook_events_array
          Integration::Successware::V202311::Base::EVENTS.map { |webhook| [webhook[:name].titleize, webhook[:event].tr('.', '_')] }
        end

        def webhook_ext_tech_ids
          @webhook.dig(:criteria, :ext_tech_ids) || []
        end

        def webhook_group
          id = @webhook.dig(:actions, :group_id).to_i
          id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
        end

        def webhook_name
          (Integration::Successware::V202311::Base::EVENTS.find { |event| event[:event] == @event_name } || { name: 'unknown' }).dig(:name).to_s.titleize
        end

        def webhook_source
          @webhook.dig(:criteria, :source) || []
        end

        def webhook_stage
          id = @webhook.dig(:actions, :stage_id).to_i
          id.positive? ? Stage.for_client(@client.id).find_by(id:) : nil
        end

        def webhook_start_date_updated
          (@webhook.dig(:criteria, :start_date_updated) || false).to_bool
        end

        def webhook_status
          @webhook.dig(:criteria, :status) || []
        end

        def webhook_stop_campaigns
          return ['All Campaigns'] if self.webhook.dig(:actions, :stop_campaign_ids)&.include?(0)

          Campaign.where(client_id: @client.id, id: self.webhook.dig(:actions, :stop_campaign_ids)).pluck(:name)
        end

        def webhook_stop_campaign_ids
          @webhook.dig(:actions, :stop_campaign_ids) || []
        end

        def webhook_tag
          id = @webhook.dig(:actions, :tag_id).to_i
          id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
        end

        def webhook_tech_updated
          (@webhook.dig(:criteria, :tech_updated) || false).to_bool
        end

        def webhook_status_updated
          (@webhook.dig(:criteria, :status_updated) || false).to_bool
        end
      end
    end
  end
end
