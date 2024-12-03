# frozen_string_literal: true

# app/presenters/integrations/pcrichard/v1/presenter.rb
module Integrations
  module Pcrichard
    module V1
      class Presenter
        attr_reader :client, :client_api_integration, :contact

        def initialize(args = {})
          self.client_api_integration = args.dig(:client_api_integration)
        end

        def after_recommendations_campaign_id
          @client_api_integration.after_recommendations&.dig('campaign_id').presence || 0
        end

        def after_recommendations_group_id
          @client_api_integration.after_recommendations&.dig('group_id').presence || 0
        end

        def after_recommendations_stage_id
          @client_api_integration.after_recommendations&.dig('stage_id').presence || 0
        end

        def after_recommendations_stop_campaign_ids
          @client_api_integration.after_recommendations&.dig('stop_campaign_ids').presence || []
        end

        def after_recommendations_tag_id
          @client_api_integration.after_recommendations&.dig('tag_id').presence || 0
        end

        def client_api_integration=(client_api_integration)
          @client_api_integration           = case client_api_integration
                                              when ClientApiIntegration
                                                client_api_integration
                                              when Integer
                                                ClientApiIntegration.find_by(id: client_api_integration)
                                              else
                                                ClientApiIntegration.new(target: 'pcrichard')
                                              end

          @client                           = @client_api_integration.client
          @client_custom_fields_for_models  = nil
          @contact                          = nil
          @contact_custom_fields_for_models = nil
          @pcrichard_model                  = nil
        end

        def client_custom_field(client_custom_field_id)
          client_custom_fields_for_models.find_by(id: client_custom_field_id)
        end

        def client_custom_fields_for_models
          @client_custom_fields_for_models ||= @client.client_custom_fields.where(id: @client_api_integration.custom_fields.select { |k, _v| k[0, 7] == 'option_' }.values).sort
        end

        def contact=(contact)
          @contact = case contact
                     when Contact
                       contact
                     when Integer
                       Contact.find_by(id: contact)
                     else
                       Contact.new
                     end
        end

        def contact_custom_field(client_custom_field_id)
          contact_custom_fields_for_models.find { |custom_field| custom_field.client_custom_field_id == client_custom_field_id } || ContactCustomField.new
        end

        def contact_custom_fields_for_models
          @contact_custom_fields_for_models ||= ContactCustomField.where(contact_id: @contact.id, client_custom_field_id: @client_api_integration.custom_fields.values).to_a
        end

        def currency_custom_fields
          ClientCustomField.currency_fields(@client)
        end

        def currently_supported_models
          self.pcrichard_model.currently_supported_models
        end

        def date_custom_fields
          ClientCustomField.date_fields(@client)
        end

        def custom_field_invoice_number_id
          @client_api_integration.leads.dig('custom_field_assignments', 'invoice_number')
        end

        def custom_field_model_number_id
          @client_api_integration.orders.dig('custom_field_assignments', 'model_number')
        end

        def numeric_custom_fields
          ClientCustomField.numeric_fields(@client)
        end

        def custom_field_option(option_id)
          @client_api_integration.custom_fields&.dig(option_id)
        end

        def custom_field_requested_at_id
          @client_api_integration.leads.dig('custom_field_assignments', 'requested_at')
        end

        def custom_field_sold_at_id
          @client_api_integration.orders.dig('custom_field_assignments', 'sold_at')
        end

        def string_custom_fields
          ClientCustomField.string_fields(@client)
        end

        def orders_campaign_id
          @client_api_integration.orders.dig('campaign_id')
        end

        def orders_group_id
          @client_api_integration.orders.dig('group_id')
        end

        def orders_stage_id
          @client_api_integration.orders.dig('stage_id')
        end

        def orders_stop_campaign_ids
          @client_api_integration.orders.dig('stop_campaign_ids')
        end

        def orders_tag_id
          @client_api_integration.orders.dig('tag_id')
        end

        def leads_campaign_id
          @client_api_integration.leads.dig('campaign_id')
        end

        def leads_group_id
          @client_api_integration.leads.dig('group_id')
        end

        def leads_stage_id
          @client_api_integration.leads.dig('stage_id')
        end

        def leads_stop_campaign_ids
          @client_api_integration.leads.dig('stop_campaign_ids')
        end

        def leads_tag_id
          @client_api_integration.leads.dig('tag_id')
        end

        def pcrichard_model
          @pcrichard_model ||= Integration::Pcrichard::V1::Base.new(@client_api_integration)
        end
      end
    end
  end
end
