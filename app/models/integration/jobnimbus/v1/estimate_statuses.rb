# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/estimate_statuses.rb
module Integration
  module Jobnimbus
    module V1
      module EstimateStatuses
        # delete a estimate status from the list of JobNimbus estimate statuses collected from webhooks
        # jn_model.estimate_status_delete()
        #   (req) status: (String)
        def estimate_status_delete(**args)
          return [] unless args.dig(:status).to_s.present? && (client_api_integration_estimate_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'estimate_statuses'))

          client_api_integration_estimate_statuses.data.delete(args[:status].to_s)
          client_api_integration_estimate_statuses.save

          client_api_integration_estimate_statuses.data.presence || []
        end

        # find a estimate status from the list of JobNimbus estimate statuses collected from webhooks
        # jn_model.estimate_status_find()
        #   (req) status: (String)
        def estimate_status_find(**args)
          return nil unless args.dig(:status).to_s.present? && (client_api_integration_estimate_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'estimate_statuses'))

          client_api_integration_estimate_statuses.data.include?(args[:status].to_s) ? args[:status].to_s : nil
        end

        # list all estimate statuses from the list of JobNimbus estimate statuses collected from webhooks
        # jn_model.estimate_status_list
        def estimate_status_list
          return [] unless (client_api_integration_estimate_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'estimate_statuses'))

          client_api_integration_estimate_statuses.data.presence || []
        end

        # update list of JobNimbus estimate statuses collected from webhooks
        # jn_model.estimate_status_update()
        #   (req) status: (String)
        def estimate_status_update(**args)
          return unless args.dig(:status).to_s.present? && (client_api_integration_estimate_statuses = @client.client_api_integrations.find_or_initialize_by(target: 'jobnimbus', name: 'estimate_statuses'))

          client_api_integration_estimate_statuses.data = ((client_api_integration_estimate_statuses.data.presence || []) << args[:status].to_s).uniq.sort
          client_api_integration_estimate_statuses.save

          client_api_integration_estimate_statuses.data.presence || []
        end
      end
    end
  end
end
