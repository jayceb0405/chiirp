# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/task_types.rb
module Integration
  module Jobnimbus
    module V1
      module TaskTypes
        # delete a task_type from the list of JobNimbus sales reps collected from webhooks
        # jn_model.task_type_delete()
        #   (req) type: (String)
        def task_type_delete(**args)
          return [] unless args.dig(:type).to_s.present? && (client_api_integration_task_types = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'task_types'))

          client_api_integration_task_types.data.delete(args[:type].to_s)
          client_api_integration_task_types.save

          client_api_integration_task_types.data.presence || []
        end

        # find a task_type from the list of JobNimbus sales reps collected from webhooks
        # jn_model.task_type_find()
        #   (req) type: (String)
        def task_type_find(**args)
          return nil unless args.dig(:type).to_s.present? && (client_api_integration_task_types = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'task_types'))

          client_api_integration_task_types.data.include?(args[:type].to_s) ? args[:type].to_s : nil
        end

        # list all task_types from the list of JobNimbus sales reps collected from webhooks
        # jn_model.task_type_list
        def task_type_list
          return [] unless (client_api_integration_task_types = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'task_types'))

          client_api_integration_task_types.data.presence || []
        end

        # update list of JobNimbus sales reps collected from webhooks
        # jn_model.task_type_update()
        #   (req) type:    (String)
        def task_type_update(**args)
          return unless args.dig(:type).to_s.present? && (client_api_integration_task_types = @client.client_api_integrations.find_or_initialize_by(target: 'jobnimbus', name: 'task_types'))

          client_api_integration_task_types.data = ((client_api_integration_task_types.data.presence || []) << args[:type].to_s).uniq.sort
          client_api_integration_task_types.save

          client_api_integration_task_types.data.presence || []
        end
      end
    end
  end
end
