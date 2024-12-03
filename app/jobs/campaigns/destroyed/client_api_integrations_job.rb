# frozen_string_literal: true

# app/jobs/campaigns/destroyed/client_api_integrations_job.rb
module Campaigns
  module Destroyed
    class ClientApiIntegrationsJob < ApplicationJob
      # remove all references to a destroyed Campaign in ClientApiIntegration
      # Campaigns::Destroyed::ClientApiIntegrationsJob.perform_now()
      # Campaigns::Destroyed::ClientApiIntegrationsJob.set(wait_until: 1.day.from_now).perform_later()
      # Campaigns::Destroyed::ClientApiIntegrationsJob.set(wait_until: 1.day.from_now, priority: 0).perform_later()
      def initialize(**args)
        super

        @process = (args.dig(:process).presence || 'campaign_destroyed').to_s
      end

      # perform the ActiveJob
      #   (req) client_id:   (Integer)
      #   (opt) campaign_id: (Integer)
      #   (opt) group_id:    (Integer)
      #   (opt) stage_id:    (Integer)
      #   (opt) tag_id:      (Integer)
      def perform(**args)
        super

        return false if Integer(args.dig(:client_id), exception: false).blank?

        if (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'cardx', name: '')).present? &&
           (cx_model = Integration::Cardx::Event.new(client_api_integration_id: client_api_integration.id)).present?

          cx_model.references_destroyed(**args)
        end

        Integration::Dope::V1::ReferencesDestroyed.references_destroyed(**args)

        if (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'jobber', name: '')).present? &&
           (jb_model = Integration::Jobber::V20231115::Base.new(client_api_integration)).present?

          jb_model.references_destroyed(**args)
        end

        if (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'housecall', name: '')).present? &&
           (hcp_model = Integration::Housecallpro::V1::Base.new(client_api_integration)).present?

          hcp_model.references_destroyed(**args)
        end

        Integration::Salesrabbit.references_destroyed(**args)
        Integration::Sendjim::V3::ReferencesDestroyed.references_destroyed(**args)
        Integration::Servicemonster.references_destroyed(**args)

        if (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'servicetitan', name: '')).present? &&
           (st_model = Integration::Servicetitan::V2::Base.new(client_api_integration)).present?

          st_model.references_destroyed(**args)
        end

        if (client_api_integration = ClientApiIntegration.find_by(client_id: args[:client_id], target: 'successware', name: '')).present? &&
           (sw_model = Integration::Successware::V202311::Base.new(client_api_integration)).present?

          sw_model.references_destroyed(**args)
        end
      end
    end
  end
end
