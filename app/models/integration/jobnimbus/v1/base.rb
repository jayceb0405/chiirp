# frozen_string_literal: true

# app/models/integration/jobnimbus/v1/base.rb
module Integration
  module Jobnimbus
    module V1
      class Base < Integration::Jobnimbus::Base
        include Integration::Jobnimbus::V1::ContactStatuses
        include Integration::Jobnimbus::V1::EstimateStatuses
        include Integration::Jobnimbus::V1::InvoiceStatuses
        include Integration::Jobnimbus::V1::JobStatuses
        include Integration::Jobnimbus::V1::SalesReps
        include Integration::Jobnimbus::V1::TaskTypes
        include Integration::Jobnimbus::V1::WorkorderStatuses

        IMPORT_BLOCK_COUNT = 25
        WEBHOOKS = [
          { name: 'Contacts', event: 'contact', description: 'Contacts' },
          { name: 'Estimates', event: 'estimate', description: 'Estimates' },
          { name: 'Jobs', event: 'job', description: 'Jobs' },
          { name: 'Work Orders', event: 'workorder', description: 'Work Orders' },
          { name: 'Invoices', event: 'invoice', description: 'Invoices' },
          { name: 'Tasks', event: 'task', description: 'Tasks' }
        ].freeze

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'jobnimbus', name: ''); jn_model = Integration::Jobnimbus::V1::Base.new(client_api_integration); jn_model.valid_credentials?; jn_client = Integrations::JobNimbus::V1::Base.new(client_api_integration.api_key)

        # jn_model = Integration::Jobnimbus::V1::Base.new()
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          self.client_api_integration = client_api_integration
        end

        # return a string that may be used to inform the User how many more JobNimbus contacts are remaining in the queue to be imported
        # Integration::Jobnimbus::V1::Base.contact_imports_remaining_string
        def contact_imports_remaining_string
          imports                 = DelayedJob.where(process: 'jobnimbus_import_contacts', locked_at: nil).where('data @> ?', { client_id: @client.id }.to_json).count
          grouped_contact_imports = DelayedJob.where(process: 'jobnimbus_import_contacts_blocks', locked_at: nil).where('data @> ?', { client_id: @client.id }.to_json).count * Integration::Jobnimbus::V1::Base::IMPORT_BLOCK_COUNT
          contact_imports         = [DelayedJob.where(process: 'jobnimbus_import_contact', locked_at: nil).where('data @> ?', { client_id: @client.id }.to_json).count - 2, 0].max

          if imports.positive? && (grouped_contact_imports + contact_imports).zero?
            'Queued'
          else
            "#{grouped_contact_imports.positive? ? '< ' : ''}#{grouped_contact_imports + contact_imports}"
          end
        end

        # update list of JobNimbus sales reps collected from webhooks
        # jn_model.update_task_types(task_type)
        #   (req) task_type: (String)
        def update_task_types(task_type)
          return if task_type.blank? || (client_api_integration.task_types || []).include?(task_type)

          @client_api_integration.update(task_types: ((@client_api_integration.task_types || []) << task_type).uniq.sort)
        end

        # validate that an api_key exists
        # jn_model.valid_credentials?
        def valid_credentials?
          @client_api_integration.api_key.present?
        end

        # jn_model.webhook_by_id()
        #   (req) webhook_event_id: (String)
        def webhook_by_id(webhook_event_id)
          webhook = @client_api_integration.webhooks.find { |_k, v| v.find { |e| e.dig('event_id').to_s == webhook_event_id } } || []
          webhook.present? ? [webhook].to_h.deep_symbolize_keys : {}
        end

        # jn_model.webhook_event_by_id()
        #   (req) webhook_event_id: (String)
        def webhook_event_by_id(webhook_event_id)
          @client_api_integration.webhooks.find { |_k, v| v.find { |x| x.dig('event_id').to_s == webhook_event_id } }&.last&.find { |x| x.dig('event_id').to_s == webhook_event_id }&.deep_symbolize_keys
        end

        # jn_model.webhook_object_by_id()
        #   (req) webhook_event_id: (String)
        def webhook_object_by_id(webhook_event_id)
          @client_api_integration.webhooks.find { |_k, v| v.find { |x| x.dig('event_id').to_s == webhook_event_id } }&.first
        end

        private

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'jobnimbus', name: '')
                                    end

          @client    = @client_api_integration.client
          @jn_client = Integrations::JobNimbus::V1::Base.new(@client_api_integration.api_key)
        end
      end
    end
  end
end
