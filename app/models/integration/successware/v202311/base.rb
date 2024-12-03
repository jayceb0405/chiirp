# frozen_string_literal: true

# app/models/integration/successware/v202311/base.rb
module Integration
  module Successware
    module V202311
      class Base
        include Successware::V202311::Event
        include Successware::V202311::ImportContacts
        include Successware::V202311::JobTypes
        include Successware::V202311::ReferencesDestroyed

        EVENTS = [
          { name: 'Job Scheduled', event: 'scheduled', description: 'Job scheduled' },
          { name: 'Job Unscheduled', event: 'unscheduled', description: 'Job unscheduled' },
          { name: 'Job Assigned', event: 'assigned', description: 'Job assigned to technician' },
          { name: 'Job Unassigned', event: 'unassigned', description: 'Job unassigned from technician' },
          { name: 'Job Rescheduled', event: 'rescheduled', description: 'Job rescheduled' },
          { name: 'Customer Notified', event: 'notified', description: 'Notification sent to customer' },
          { name: 'Technician OnSite', event: 'onsight', description: 'Technician is on site' },
          { name: 'Technician Dispatched', event: 'dispatched', description: 'Technician is dispatched' },
          { name: 'Job Completed', event: 'completed', description: 'Job completed' },
          { name: 'Job Closed', event: 'closed', description: 'Job closed' },
          { name: 'Job Cancelled', event: 'canceled', description: 'Job cancelled' }
        ].freeze

        # client_id = xx
        # client_api_integration = ClientApiIntegration.find_by(client_id: client_id, target: 'successware', name: ''); sw_model = Integration::Successware::V202311::Base.new(client_api_integration); sw_model.valid_credentials?; sw_client = Integrations::SuccessWare::V202311::Base.new(client_api_integration.credentials)

        # sw_model = Integration::Successware::V202311::Base.new()
        #   (req) client_api_integration: (ClientApiIntegration)
        def initialize(client_api_integration = nil)
          self.client_api_integration = client_api_integration
        end

        def create_or_update_successware_customer(contact:, customer_type:, lead_source_id:, lead_source_type_id:)
          return unless self.valid_credentials?

          contact_attrs = contact.attributes.deep_dup.symbolize_keys
          contact_attrs[:phone_numbers]       = contact.contact_phones.map { |phone| phone.attributes.symbolize_keys }
          contact_attrs[:customer_type]       = customer_type
          contact_attrs[:lead_source_id]      = lead_source_id
          contact_attrs[:lead_source_type_id] = lead_source_type_id

          if (contact_ext_reference = contact.ext_references.find_by(target: 'successware'))
            @sw_client.customer_update(contact_ext_reference.ext_id, contact_attrs)
          else
            @sw_client.customer_create(contact_attrs)
          end

          return unless @sw_client.success? && (contact_ext_reference = contact.ext_references.find_or_create_by(target: 'successware'))

          contact_ext_reference.update(ext_id: @sw_client.result)
        end

        # delete Successware credentials
        # sw_model.delete_credentials
        def delete_credentials
          JsonLog.info 'Integration::Successware::202311::Base.delete_credentials', { client_api_integration: @client_api_integration }, client_id: @client.id
          @client_api_integration.credentials['access_token'] = ''
          @client_api_integration.credentials['user_name'] = ''
          @client_api_integration.credentials['password'] = ''
          update_credentials_expiration_and_version(@client_api_integration)
        end

        # disconnect Client from Successware
        # sw_model.disconnect_account
        def disconnect_account
          JsonLog.info 'Integration::Successware::V202311::Base.disconnect_account', { client_api_integration: @client_api_integration }, client_id: @client.id
          valid_credentials?(@client_api_integration)
          sw_client = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials)
          sw_client.disconnect_account

          delete_credentials(@client_api_integration) if sw_client.success?

          sw_client.success?
        end

        # tag was applied / submit Contact to Successware
        # sw_model.tag_applied()
        #   (req) contacttag: (Contacttag)
        def tag_applied(args = {})
          return unless args.dig(:contacttag).is_a?(Contacttag) && (push_contact_tag = @client_api_integration.push_contact_tags.find { |pct| pct.dig('tag_id') == args[:contacttag].tag_id.to_i })

          self.create_or_update_successware_customer(contact: args[:contacttag].contact, customer_type: push_contact_tag.dig('customer_type'), lead_source_id: push_contact_tag.dig('lead_source_id'), lead_source_type_id: push_contact_tag.dig('lead_source_type_id'))
        end

        # update ClientApiIntegration.credentials from code or user_name/password
        # sw_model.update_credentials
        def update_credentials
          if @client_api_integration.credentials.dig('user_name').present? && @client_api_integration.credentials.dig('password').present?
            @client_api_integration.credentials = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials).refresh_access_token.merge({ 'user_name' => @client_api_integration.credentials.dig('user_name'), 'password' => @client_api_integration.credentials.dig('password') })
            @sw_client = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials)
            self.update_credentials_expiration_and_version
          else
            @client_api_integration.update(credentials: {})
          end

          @client_api_integration.credentials.dig('user_name').present? && @client_api_integration.credentials.dig('password').present?
        end

        # update ClientApiIntegration.credentials expires_at & version
        # sw_model.update_credentials_expiration_and_version
        def update_credentials_expiration_and_version
          if @client_api_integration.credentials.dig('access_token').present? && @client_api_integration.credentials.dig('user_name').present? && @client_api_integration.credentials.dig('password').present?
            @client_api_integration.credentials[:expires_at] = Time.current + (@client_api_integration.credentials.dig('expires_in') || 86_399) - 5.minutes
            @client_api_integration.credentials[:version]    = '202311'
            @client_api_integration.save
          else
            @client_api_integration.update(credentials: {})
          end
        end

        # validate the access_token & refresh if necessary
        # sw_model.valid_credentials?
        def valid_credentials?
          if @client_api_integration.credentials.dig('access_token').present? &&
             @client_api_integration.credentials.dig('user_name').present? &&
             @client_api_integration.credentials.dig('password').present? &&
             @client_api_integration.credentials.dig('expires_at').present? &&
             @client_api_integration.credentials.dig('expires_at') > 1.minute.from_now
            true
          else
            self.update_credentials
          end
        end

        private

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new(target: 'successware', name: '')
                                    end

          @client    = @client_api_integration.client
          @sw_client = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials)
        end
      end
    end
  end
end
