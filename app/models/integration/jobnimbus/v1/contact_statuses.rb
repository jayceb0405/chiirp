# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/contact_statuses.rb
module Integration
  module Jobnimbus
    module V1
      module ContactStatuses
        # delete a contact status from the list of JobNimbus contact statuses collected from webhooks
        # jn_model.contact_status_delete()
        #   (req) status: (String)
        def contact_status_delete(**args)
          return [] unless args.dig(:status).to_s.present? && (client_api_integration_contact_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'contact_statuses'))

          client_api_integration_contact_statuses.data.delete(args[:status].to_s)
          client_api_integration_contact_statuses.save

          client_api_integration_contact_statuses.data.presence || []
        end

        # find a contact status from the list of JobNimbus contact statuses collected from webhooks
        # jn_model.contact_status_find()
        #   (req) status: (String)
        def contact_status_find(**args)
          return nil unless args.dig(:status).to_s.present? && (client_api_integration_contact_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'contact_statuses'))

          client_api_integration_contact_statuses.data.include?(args[:status].to_s) ? args[:status].to_s : nil
        end

        # list all contact statuses from the list of JobNimbus contact statuses collected from webhooks
        # jn_model.contact_status_list
        def contact_status_list
          return [] unless (client_api_integration_contact_statuses = @client.client_api_integrations.find_by(target: 'jobnimbus', name: 'contact_statuses'))

          client_api_integration_contact_statuses.data.presence || []
        end

        # update list of JobNimbus contact statuses collected from webhooks
        # jn_model.contact_status_update()
        #   (req) status: (String)
        def contact_status_update(**args)
          return unless args.dig(:status).to_s.present? && (client_api_integration_contact_statuses = @client.client_api_integrations.find_or_initialize_by(target: 'jobnimbus', name: 'contact_statuses'))

          client_api_integration_contact_statuses.data = ((client_api_integration_contact_statuses.data.presence || []) << args[:status].to_s).uniq.sort
          client_api_integration_contact_statuses.save

          client_api_integration_contact_statuses.data.presence || []
        end
      end
    end
  end
end
