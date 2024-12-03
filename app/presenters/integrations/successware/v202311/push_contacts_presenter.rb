# frozen_string_literal: true

# app/presenters/integrations/successware/v202311/push_contacts_presenter.rb
module Integrations
  module Successware
    module V202311
      class PushContactsPresenter
        attr_reader :api_key, :client, :client_api_integration, :push_contact_tag

        def initialize(args = {})
          self.client_api_integration = args.dig(:client_api_integration)
        end

        def client_api_integration=(client_api_integration)
          @client_api_integration = case client_api_integration
                                    when ClientApiIntegration
                                      client_api_integration
                                    when Integer
                                      ClientApiIntegration.find_by(id: client_api_integration)
                                    else
                                      ClientApiIntegration.new
                                    end

          @api_key                       = @client_api_integration.api_key
          @client                        = @client_api_integration.client
          @client_tags                   = @client.tags.select(:id, :name)
          @credentials                   = self.credentials
          @push_contact_tag              = nil
          @push_contact_tag_tag          = nil
          @sorted_push_contact_tags      = nil
          @successware_lead_sources      = nil
          @successware_lead_source_types = nil

          @sw_client = Integrations::SuccessWare::V202311::Base.new(@client_api_integration.credentials)
        end

        def credentials
          Integration::Successware::V202311::Base.new(@client_api_integration).valid_credentials? ? @client_api_integration.credentials : {}
        end

        def customer_type_options
          [
            %w[Residential],
            %w[Commercial]
          ]
        end

        def push_contact_tag=(push_contact_tag)
          @push_contact_tag = push_contact_tag&.symbolize_keys
        end

        def push_contact_tag_customer_type
          @push_contact_tag&.dig(:customer_type).to_s
        end

        def push_contact_tag_id
          @push_contact_tag&.dig(:id).to_s
        end

        def push_contact_tag_tag
          @push_contact_tag_tag ||= @client.tags.find_by(id: @push_contact_tag&.dig(:tag_id)).presence || @client.tags.new
        end

        def push_contact_tag_tag_id
          @push_contact_tag&.dig(:tag_id).to_i
        end

        def push_contact_tag_tag_name
          self.push_contact_tag_tag.name
        end

        def push_contact_tag_lead_source
          self.successware_lead_sources.find { |sls| sls.dig(:id).to_i == @push_contact_tag&.dig(:lead_source_id) }
        end

        def push_contact_tag_lead_source_id
          @push_contact_tag&.dig(:lead_source_id)
        end

        def push_contact_tag_lead_source_name
          self.push_contact_tag_lead_source.present? ? "(#{self.push_contact_tag_lead_source&.dig(:code).presence || '?'}) #{self.push_contact_tag_lead_source&.dig(:description).presence || 'Unknown'}" : ''
        end

        def push_contact_tag_lead_source_type
          self.successware_lead_source_types.find { |slst| slst.dig(:id).to_i == @push_contact_tag.dig('lead_source_type_id') }
        end

        def push_contact_tag_lead_source_type_name
          self.push_contact_tag_lead_source_type&.dig(:code)
        end

        def push_contact_tag_name
          @client_tags.find { |tag| tag[:id] == 123 }&.name.presence || 'Not Selected'
        end

        def push_contacts
          @client_api_integration.push_contacts&.map(&:deep_symbolize_keys) || []
        end

        def sorted_push_contact_tags
          unless @sorted_push_contact_tags
            tags = Tag.where(id: @client_api_integration.push_contact_tags.map { |pc| pc.dig(:tag_id) }).pluck(:id, :name)
            @sorted_push_contact_tags = @client_api_integration.push_contact_tags.map { |pc| pc.merge(tag_name: tags.select { |t| t.first == pc.dig(:tag_id) }&.flatten&.last.to_s) }.sort_by { |pc| pc.dig(:tag_name) }
          end

          @sorted_push_contact_tags
        end

        def successware_lead_source_options
          self.successware_lead_sources.map { |sls| ["(#{sls.dig(:code)}) #{sls.dig(:description)}", sls.dig(:id)] }
        end

        def successware_lead_sources
          @successware_lead_sources ||= @sw_client.lead_sources
        end
      end
    end
  end
end
