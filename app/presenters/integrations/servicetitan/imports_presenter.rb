# frozen_string_literal: true

# app/presenters/integrations/servicetitan/imports_presenter.rb
module Integrations
  module Servicetitan
    class ImportsPresenter
      attr_accessor :event
      attr_reader   :api_key, :client, :client_api_integration

      # Integrations::Servicetitan::EventsPresenter.new()
      # client_api_integration: (ClientApiIntegration)
      def initialize(client_api_integration)
        self.client_api_integration = client_api_integration
      end

      def business_units
        @business_units ||= @st_model.business_units.sort_by { |e| e[0] }
      end

      def campaign_0
        @campaign_0 ||= (@client_api_integration.import['campaign_id_0'].to_i.positive? ? @client.campaigns.find_by(id: @client_api_integration.import['campaign_id_0'].to_i) : nil) || @client.campaigns.new
      end

      def campaign_above_0
        @campaign_above_0 ||= (@client_api_integration.import['campaign_id_above_0'].to_i.positive? ? @client.campaigns.find_by(id: @client_api_integration.import['campaign_id_above_0'].to_i) : nil) || @client.campaigns.new
      end

      def campaign_below_0
        @campaign_below_0 ||= (@client_api_integration.import['campaign_id_below_0'].to_i.positive? ? @client.campaigns.find_by(id: @client_api_integration.import['campaign_id_below_0'].to_i) : nil) || @client.campaigns.new
      end

      def client_api_integration=(client_api_integration)
        @client_api_integration    = case client_api_integration
                                     when ClientApiIntegration
                                       client_api_integration
                                     when Integer
                                       ClientApiIntegration.find_by(id: client_api_integration)
                                     else
                                       ClientApiIntegration.new
                                     end
        @api_key                   = @client_api_integration.api_key
        @business_units            = nil
        @client                    = @client_api_integration.client
        @campaign_0                = nil
        @campaign_above_0          = nil
        @campaign_below_0          = nil
        @customer_count            = nil
        @group_0                   = nil
        @group_above_0             = nil
        @group_below_0             = nil
        @job_types                 = nil
        @stage_0                   = nil
        @stage_above_0             = nil
        @stage_below_0             = nil
        @stop_campaign_ids_0       = nil
        @stop_campaign_ids_above_0 = nil
        @stop_campaign_ids_below_0 = nil
        @tag_0                     = nil
        @tag_above_0               = nil
        @tag_below_0               = nil

        @st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
        @st_model  = Integration::Servicetitan::V2::Base.new(@client_api_integration)
      end

      def customer_count(current_user)
        @customer_count ||= @st_model.import_contacts_remaining_count(current_user.id)
      end

      def group_0
        @group_0 ||= (@client_api_integration.import['group_id_0'].to_i.positive? ? @client.groups.find_by(id: @client_api_integration.import['group_id_0'].to_i) : nil) || @client.groups.new
      end

      def group_above_0
        @group_above_0 ||= (@client_api_integration.import['group_id_above_0'].to_i.positive? ? @client.groups.find_by(id: @client_api_integration.import['group_id_above_0'].to_i) : nil) || @client.groups.new
      end

      def group_below_0
        @group_below_0 ||= (@client_api_integration.import['group_id_below_0'].to_i.positive? ? @client.groups.find_by(id: @client_api_integration.import['group_id_below_0'].to_i) : nil) || @client.groups.new
      end

      def import_contacts_remaining_string(current_user)
        @st_model.import_contacts_remaining_string(current_user.id).presence || (customer_count(current_user).positive? ? "#{customer_count(current_user)} Contacts remaining to be imported." : '')
      end

      def job_types
        @job_types ||= @st_model.job_types.sort_by { |e| e[0] }
      end

      def stage_0
        @stage_0 ||= (@client_api_integration.import['stage_id_0'].to_i.positive? ? Stage.for_client(@client_id).find_by(id: @client_api_integration.import['stage_id_0'].to_i) : nil) || Stage.for_client(@client_id).new
      end

      def stage_above_0
        @stage_above_0 ||= (@client_api_integration.import['stage_id_above_0'].to_i.positive? ? Stage.for_client(@client_id).find_by(id: @client_api_integration.import['stage_id_above_0'].to_i) : nil) || Stage.for_client(@client_id).new
      end

      def stage_below_0
        @stage_below_0 ||= (@client_api_integration.import['stage_id_below_0'].to_i.positive? ? Stage.for_client(@client_id).find_by(id: @client_api_integration.import['stage_id_below_0'].to_i) : nil) || Stage.for_client(@client_id).new
      end

      def stop_campaign_ids_0
        @stop_campaign_ids_0 ||= @client_api_integration.import['stop_campaign_ids_0'].presence || nil
      end

      def stop_campaign_ids_0_names
        @stop_campaign_ids_0_names ||= self.stop_campaign_ids_0&.map { |id| id.to_i.zero? ? 'All Campaigns' : Campaign.find_by(id:)&.name } || []
      end

      def stop_campaign_ids_above_0
        @stop_campaign_ids_above_0 ||= @client_api_integration.import['stop_campaign_ids_above_0'].presence || nil
      end

      def stop_campaign_ids_above_0_names
        @stop_campaign_ids_above_0_names ||= self.stop_campaign_ids_above_0&.map { |id| id.to_i.zero? ? 'All Campaigns' : Campaign.find_by(id:)&.name } || []
      end

      def stop_campaign_ids_below_0
        @stop_campaign_ids_below_0 ||= @client_api_integration.import['stop_campaign_ids_below_0'].presence || nil
      end

      def stop_campaign_ids_below_0_names
        @stop_campaign_ids_below_0_names ||= self.stop_campaign_ids_below_0&.map { |id| id.to_i.zero? ? 'All Campaigns' : Campaign.find_by(id:)&.name } || []
      end

      def tag_0
        @tag_0 ||= (@client_api_integration.import['tag_id_0'].to_i.positive? ? @client.tags.find_by(id: @client_api_integration.import['tag_id_0'].to_i) : nil) || @client.tags.new
      end

      def tag_above_0
        @tag_above_0 ||= (@client_api_integration.import['tag_id_above_0'].to_i.positive? ? @client.tags.find_by(id: @client_api_integration.import['tag_id_above_0'].to_i) : nil) || @client.tags.new
      end

      def tag_below_0
        @tag_below_0 ||= (@client_api_integration.import['tag_id_below_0'].to_i.present? ? @client.tags.find_by(id: @client_api_integration.import['tag_id_below_0'].to_i) : nil) || @client.tags.new
      end
    end
  end
end
