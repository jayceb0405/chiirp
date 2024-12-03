# frozen_string_literal: true

# app/presenters/integrations/callrail/v3/presenter.rb
module Integrations
  module Callrail
    module V3
      class Presenter < BasePresenter
        attr_reader :event, :event_name, :events, :account_id, :company_id

        # Integrations::Callrail::V3::Presenter.new(client_api_integration: @client_api_integration)
        #   (req) client_api_integration: (ClientApiIntegration) or (Integer)
        def client_api_integration=(client_api_integration)
          super
          @event                       = nil
          @event_name                  = ''
          @events                      = @client_api_integration.events
          @cr_client                   = Integrations::CallRail::V3::Base.new(@client_api_integration.credentials)
          @products                    = nil
          @products_grouped_for_select = nil
          @ext_tech_options_for_select = nil
          @call_rail_tags              = nil
        end

        def accounts
          @cr_client.accounts
        end

        def account_id=(id)
          @account_id = id
          @cr_client = Integrations::CallRail::V3::Base.new(@client_api_integration.credentials, account_id:, company_id:)
        end

        def account_and_company_id=(account_company_id)
          return unless account_company_id

          @account_id, @company_id = Integration::Callrail::V3::Base.split_account_company_id(account_company_id)
          @cr_client = Integrations::CallRail::V3::Base.new(@client_api_integration.credentials, account_id:, company_id:)
        end

        def account_options
          @cr_client.accounts.map { |account| [account[:name], account[:id]] }
        end

        def available_tags
          @available_tags ||= @cr_client.available_tags.map { |tag| [tag[:name]] }.uniq.sort
        end

        def campaigns_allowed
          @client.campaigns_count.positive?
        end

        def company_id=(id)
          @company_id = id
          @cr_client = Integrations::CallRail::V3::Base.new(@client_api_integration.credentials, account_id:, company_id:)
        end

        def form_submission(id)
          @cr_client.form_submission(company_id, id)
        end

        def form_names
          @cr_client.form_submissions(company_id).pluck(:form_name).uniq
        end

        def grouped_companies
          @cr_client.all_companies.map { |account, companies| [account[:name], companies.map { |company| [company[:name], "#{account[:id]}::#{company[:id]}"] }] }
        end

        def groups_allowed
          @client.groups_count.positive?
        end

        def event=(event)
          @event = event&.deep_symbolize_keys
        end

        def event_campaign
          id = @event.dig(:action, :campaign_id).to_i
          id.positive? ? Campaign.find_by(client_id: @client.id, id:) : nil
        end

        def event_company_name
          return nil unless @company_id

          @cr_client.company_name_from_id(@company_id)
        end

        def event_group
          id = @event.dig(:action, :group_id).to_i
          id.positive? ? Group.find_by(client_id: @client.id, id:) : nil
        end

        def event_keywords
          return [] unless @event

          @event[:keywords].join(', ')
        end

        def event_stage
          id = @event.dig(:action, :stage_id).to_i
          id.positive? ? Stage.for_client(@client.id).find_by(id:) : nil
        end

        def event_stop_campaigns
          return ['All Campaigns'] if self.event_stop_campaign_ids&.include?(0)

          Campaign.where(client_id: @client.id, id: self.event_stop_campaign_ids).pluck(:name)
        end

        def event_stop_campaign_ids
          @event.dig(:action, :stop_campaign_ids)&.compact_blank
        end

        def event_tag
          id = @event.dig(:action, :tag_id).to_i
          id.positive? ? Tag.find_by(client_id: @client.id, id:) : nil
        end

        def event_type
          @event.dig(:type)&.titleize || 'Undefined'
        end

        def form_method
          @event.present? ? :patch : :post
        end

        def form_url
          @event.present? && @event.include?(:event_id) ? Rails.application.routes.url_helpers.integrations_callrail_v3_event_path(@event[:event_id]) : Rails.application.routes.url_helpers.integrations_callrail_v3_events_path
        end

        def tracking_phone_numbers
          @cr_client.tracking_phone_numbers.map { |phone| [ActionController::Base.helpers.number_to_phone(phone.clean_phone(@client_api_integration&.client&.primary_area_code)), phone.clean_phone(@client_api_integration&.client&.primary_area_code)] }
        end

        def source_names
          @cr_client.source_names
        end

        def stages_allowed
          @client.stages_count.positive?
        end

        # verify that Jobber credentials are valid
        # presenter.connection_valid?
        def valid_credentials?
          @valid_credentials ||= @cr_client.valid_credentials?
        end
      end
    end
  end
end
