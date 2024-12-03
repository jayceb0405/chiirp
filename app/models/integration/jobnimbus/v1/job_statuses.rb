# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/job_statuses.rb
module Integration
  module Jobnimbus
    module V1
      module JobStatuses
        # delete a job status from the list of JobNimbus job statuses collected from webhooks
        # jn_model.job_status_delete()
        #   (req) status: (String)
        def job_status_delete(**args)
          return [] unless args.dig(:status).to_s.present? && (client_api_integration_job_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'job_statuses'))

          client_api_integration_job_statuses.data.delete(args[:status].to_s)
          client_api_integration_job_statuses.save

          client_api_integration_job_statuses.data.presence || []
        end

        # find a job status from the list of JobNimbus job statuses collected from webhooks
        # jn_model.job_status_find()
        #   (req) status: (String)
        def job_status_find(**args)
          return nil unless args.dig(:status).to_s.present? && (client_api_integration_job_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'job_statuses'))

          client_api_integration_job_statuses.data.include?(args[:status].to_s) ? args[:status].to_s : nil
        end

        # list all job statuses from the list of JobNimbus job statuses collected from webhooks
        # jn_model.job_status_list
        def job_status_list
          return [] unless (client_api_integration_job_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'job_statuses'))

          client_api_integration_job_statuses.data.presence || []
        end

        # update list of JobNimbus job statuses collected from webhooks
        # jn_model.job_status_update()
        #   (req) status: (String)
        def job_status_update(**args)
          return unless args.dig(:status).to_s.present? && (client_api_integration_job_statuses = @client.client_api_integrations.find_or_initialize_by(target: 'jobnimbus', name: 'job_statuses'))

          client_api_integration_job_statuses.data = ((client_api_integration_job_statuses.data.presence || []) << args[:status].to_s).uniq.sort
          client_api_integration_job_statuses.save

          client_api_integration_job_statuses.data.presence || []
        end
      end
    end
  end
end
