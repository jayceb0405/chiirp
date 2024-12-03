# frozen_string_literal: true

# app/presenters/integrations/jobber/v20231115/presenter.rb
module Integrations
  module Jobber
    module V20231115
      class Presenter < BasePresenter
        attr_reader :event, :event_name, :events, :webhook, :webhooks, :webhook_id

        # Integrations::Jobber::V20231115::Presenter.new(client_api_integration: @client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration) or (Integer)

        def campaigns_allowed
          @client.campaigns_count.positive?
        end

        def client_api_integration=(client_api_integration)
          super
          @event                       = nil
          @event_name                  = ''
          @events                      = []
          @jb_client                   = Integrations::JobBer::V20231115::Base.new(@client_api_integration.credentials)
          @jb_model                    = Integration::Jobber::V20231115::Base.new(@client_api_integration)
          @jobber_employees            = nil
          @products                    = nil
          @products_grouped_for_select = nil
          @ext_tech_options_for_select = nil
          @webhook                     = nil
          @webhook_id                  = nil
          @webhooks                    = @client_api_integration.webhooks&.deep_symbolize_keys || []
        end

        # return URL used to request authorization code from Jobber
        def connect_to_jobber_url
          @jb_model.connect_to_jobber_url
        end

        def contact_imports_remaining_string(user_id)
          @jb_model.import_contacts_remaining_string(user_id)
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
          @ext_tech_options_for_select ||= @jb_client.users.map { |u| [u[:name][:full], u[:id]] }
        end

        def form_method
          @webhook_id.present? ? :patch : :post
        end

        def form_url
          @webhook_id.present? ? Rails.application.routes.url_helpers.integrations_jobber_v20231115_webhook_path(@webhook_id, event: @event_name) : Rails.application.routes.url_helpers.integrations_jobber_v20231115_webhooks_path
        end

        def groups_allowed
          @client.groups_count.positive?
        end

        def jobber_employees
          @jobber_employees ||= @jb_client.users.sort_by { |u| u.dig(:name, :full) }
        end

        def jobber_employees_linked
          self.jobber_employees.present? ? self.client_api_integration.employees&.values&.delete_if(&:zero?)&.count.to_f / self.jobber_employees.length : 0
        end

        def options_for_request_source
          (@client_api_integration.request_sources || []).map { |request_source| [request_source.titleize, request_source] }
        end

        def products
          @products ||= @jb_client.products
        end

        def products_grouped_for_select
          @products_grouped_for_select ||= products.pluck(:category).uniq.compact_blank.sort.map { |c| [c, products.select { |sp| sp[:category] == c }.sort_by { |s| s[:name].downcase }.map { |p| [p[:name], p[:id]] }] }
        end

        def push_leads_customer_tag
          Tag.find_by(client_id: @client.id, id: @client_api_integration.push_contacts_tag_id)
        end

        def push_leads_legend_string_customer
          'Tag to Push Contact to Jobber'
        end

        def stages_allowed
          @client.stages_count.positive?
        end

        def status_for_select(event_name = @event_name)
          case event_name&.split('_')&.first
          when 'invoice'
            Integration::Jobber::V20231115::Base::INVOICE_STATUSES
          when 'job'
            Integration::Jobber::V20231115::Base::JOB_STATUSES
          when 'quote'
            Integration::Jobber::V20231115::Base::QUOTE_STATUSES
          when 'request'
            Integration::Jobber::V20231115::Base::REQUEST_STATUSES
          when 'visit'
            Integration::Jobber::V20231115::Base::VISIT_STATUSES
          else
            []
          end
        end

        # verify that Jobber credentials are valid
        # presenter.connection_valid?
        def valid_credentials?
          @jb_model.valid_credentials?
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
          Integration::Jobber::V20231115::Base::EVENTS.map { |webhook| [webhook[:name].titleize, webhook[:event].tr('.', '_')] }
        end

        def webhook_ext_tech_ids
          @webhook.dig(:criteria, :ext_tech_ids) || []
        end

        def webhook_group
          id = @webhook.dig(:actions, :group_id).to_i
          id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
        end

        def webhook_line_items
          @webhook.dig(:criteria, :line_items) || []
        end

        def webhook_line_item_names
          # @webhook_line_items.map { |line_item| @client_api_integration.price_book.dig(line_item)&.dig('name') }.compact_blank.join(', ')
          []
        end

        def webhook_name
          (Integration::Jobber::V20231115::Base::EVENTS.find { |event| event[:event] == @event_name } || { name: 'unknown' }).dig(:name).to_s.titleize
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
