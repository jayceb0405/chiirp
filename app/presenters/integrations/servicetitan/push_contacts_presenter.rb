# frozen_string_literal: true

# app/presenters/integrations/servicetitan/push_contacts_presenter.rb
module Integrations
  module Servicetitan
    class PushContactsPresenter
      attr_accessor :push_contact
      attr_reader   :api_key, :client, :client_api_integration

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

        @st_model                              = Integration::Servicetitan::V2::Base.new(@client_api_integration)
        @api_key                               = @client_api_integration.api_key
        @client                                = @client_api_integration.client
        @push_contacts_custom_field_id_options = nil
        @credentials                           = self.credentials
        @push_contact                          = nil
        @sorted_push_contacts                  = nil
        @servicetitan_business_units           = nil
        @servicetitan_campaigns                = nil
        @servicetitan_employees                = nil
        @servicetitan_technicians              = nil
        @servicetitan_job_types                = nil

        @st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
      end

      def credentials
        @st_model.valid_credentials? ? @client_api_integration.credentials : {}
      end

      def push_contact_booking_provider_id
        @push_contact&.dig(:booking_provider_id).to_i
      end

      def push_contact_booking_source
        @push_contact&.dig(:booking_source).to_s
      end

      def push_contact_business_unit_id
        @push_contact&.dig(:business_unit_id).to_i
      end

      def push_contacts_business_unit_id_options
        self.servicetitan_business_units || []
      end

      def push_contact_campaign_id
        @push_contact&.dig(:campaign_id).to_i
      end

      def push_contacts_campaign_id_options
        self.servicetitan_campaigns || []
      end

      def push_contact_custom_field_id
        @push_contact&.dig(:summary_client_custom_field_id).to_i
      end

      def push_contacts_custom_field_id_options
        @push_contacts_custom_field_id_options ||= @client.client_custom_fields.where(var_type: 'string').pluck(:var_name, :id)
      end

      def push_contact_customer_type
        @push_contact&.dig(:customer_type).to_s
      end

      def push_contacts_customer_type_options
        [
          %w[Residential],
          %w[Commercial]
        ]
      end

      def push_contact_id
        @push_contact&.dig(:id).to_s
      end

      def push_contact_job_type_id
        @push_contact&.dig(:job_type_id).to_i
      end

      def push_contacts_job_type_id_options
        self.servicetitan_job_types || []
      end

      def push_contact_priority
        @push_contact&.dig(:priority).to_s
      end

      def push_contacts_priority_options
        [
          %w[Low],
          %w[Normal],
          %w[High],
          %w[Urgent]
        ]
      end

      def push_contact_tag
        @client.tags.find_by(id: self.push_contact_tag_id) || @client.tags.new
      end

      def push_contact_tag_id
        @push_contact&.dig(:tag_id).to_i
      end

      def push_contact_type
        @push_contact&.dig(:type).to_s
      end

      def push_contacts
        @client_api_integration.push_contacts&.map(&:deep_symbolize_keys) || []
      end

      def push_contacts_type_options
        [
          %w[Customer],
          %w[Booking]
        ]
      end

      def servicetitan_business_units
        @servicetitan_business_units ||= @st_model.business_units
      end

      def servicetitan_campaigns
        @servicetitan_campaigns ||= @st_model.campaigns
      end

      def servicetitan_job_types
        @servicetitan_job_types ||= @st_model.job_types
      end

      def sorted_push_contacts
        unless @sorted_push_contacts
          tags = Tag.where(id: self.push_contacts.map { |pc| pc.dig(:tag_id) }).pluck(:id, :name)
          @sorted_push_contacts = self.push_contacts.map { |pc| pc.merge(tag_name: tags.select { |t| t.first == pc.dig(:tag_id) }&.flatten&.last.to_s) }.sort_by { |pc| pc.dig(:tag_name) }
        end

        @sorted_push_contacts
      end
    end
  end
end
