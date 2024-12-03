# frozen_string_literal: true

# app/presenters/integrations/servicetitan/presenter.rb
module Integrations
  module Servicetitan
    class Presenter
      attr_accessor :api_key, :client, :event
      attr_reader   :client_api_integration

      def initialize(args = {})
        self.client_api_integration = args.dig(:client_api_integration)
      end

      def campaigns_allowed?
        @client.campaigns_count.positive?
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

        @st_model                    = Integration::Servicetitan::V2::Base.new(@client_api_integration)
        @api_key                     = @client_api_integration.api_key
        @client                      = @client_api_integration.client
        @credentials                 = self.credentials
        @ext_tech_collection_options = nil
        @job_imports_remaining       = nil
        @servicetitan_campaigns      = nil
        @servicetitan_employees      = nil
        @servicetitan_technicians    = nil
        @st_client                   = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
      end

      def credentials
        @st_model.valid_credentials? ? @client_api_integration.credentials : {}
      end

      def groups_allowed?
        @client.groups_count.positive?
      end

      def job_imports_remaining
        @job_imports_remaining ||= @st_model.job_imports_remaining_string(@client.id)
      end

      def options_for_date_period
        [
          ['First Appointment Period', 'first_appt'],
          ['Any Appointment Period', 'any_appt'],
          ['Job Created Period', 'job_created'],
          ['Job Modified Period', 'job_modified'],
          ['Job Completed Period', 'job_completed']
        ]
      end

      def push_leads_customer_tag
        Tag.find_by(client_id: @client.id, id: self.client_api_integration.push_leads&.dig('customer_tag_id').to_i)
      end

      def push_leads_booking_tag
        Tag.find_by(client_id: @client.id, id: self.client_api_integration.push_leads&.dig('booking_tag_id').to_i)
      end

      def push_leads_legend_string_customer
        'Tag to Push Contact to ServiceTitan'
      end

      def push_leads_legend_string_booking
        'Tag to Push Contact to ServiceTitan'
      end

      def servicetitan_campaigns
        if @servicetitan_campaigns.nil?
          result = Integrations::ServiceTitan::Base.new(@credentials).campaigns
          @servicetitan_campaigns = result.sort_by { |e| e[0] }
        end

        @servicetitan_campaigns
      end

      def servicetitan_employees
        @servicetitan_employees ||= @st_model.employees
      end

      def servicetitan_technicians
        @servicetitan_technicians ||= @st_model.technicians || []
      end

      def servicetitan_technicians_last_updated
        @st_model.technicians_last_updated
      end

      def stages_allowed?
        @client.stages_count.positive?
      end
    end
  end
end
