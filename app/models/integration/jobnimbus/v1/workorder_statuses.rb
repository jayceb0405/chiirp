# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/workorder_statuses.rb
module Integration
  module Jobnimbus
    module V1
      module WorkorderStatuses
        # delete a workorder status from the list of JobNimbus workorder statuses collected from webhooks
        # jn_model.workorder_status_delete()
        #   (req) status: (String)
        def workorder_status_delete(**args)
          return [] unless args.dig(:status).to_s.present? && (client_api_integration_workorder_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'workorder_statuses'))

          client_api_integration_workorder_statuses.data.delete(args[:status].to_s)
          client_api_integration_workorder_statuses.save

          client_api_integration_workorder_statuses.data.presence || []
        end

        # find a workorder status from the list of JobNimbus workorder statuses collected from webhooks
        # jn_model.workorder_status_find()
        #   (req) status: (String)
        def workorder_status_find(**args)
          return nil unless args.dig(:status).to_s.present? && (client_api_integration_workorder_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'workorder_statuses'))

          client_api_integration_workorder_statuses.data.include?(args[:status].to_s) ? args[:status].to_s : nil
        end

        # list all workorder statuses from the list of JobNimbus workorder statuses collected from webhooks
        # jn_model.workorder_status_list
        def workorder_status_list
          return [] unless (client_api_integration_workorder_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'workorder_statuses'))

          client_api_integration_workorder_statuses.data.presence || []
        end

        # update list of JobNimbus workorder statuses collected from webhooks
        # jn_model.workorder_status_update()
        #   (req) status: (String)
        def workorder_status_update(**args)
          return unless args.dig(:status).to_s.present? && (client_api_integration_workorder_statuses = @client.client_api_integrations.find_or_initialize_by(target: 'jobnimbus', name: 'workorder_statuses'))

          client_api_integration_workorder_statuses.data = ((client_api_integration_workorder_statuses.data.presence || []) << args[:status].to_s).uniq.sort
          client_api_integration_workorder_statuses.save

          client_api_integration_workorder_statuses.data.presence || []
        end
      end
    end
  end
end
