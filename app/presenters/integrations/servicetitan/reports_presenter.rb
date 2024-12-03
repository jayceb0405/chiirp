# frozen_string_literal: true

# app/presenters/integrations/servicetitan/reports_presenter.rb
module Integrations
  module Servicetitan
    class ReportsPresenter < BasePresenter
      attr_reader :client, :client_api_integration, :report, :report_error, :report_message

      def initialize(args = {})
        super

        @client_api_integration_report_categories = nil
        @client_api_integration_reports           = nil
        @client_api_integration_scheduled_reports = nil
        @servicetitan_business_units              = nil
        @report_error                             = nil
        @report_message                           = nil
        @report_results                           = nil

        @st_model = Integration::Servicetitan::V2::Base.new(@client_api_integration)
        @st_model.valid_credentials?
        @st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials)
      end

      def business_units_for_select
        self.servicetitan_business_units.map { |bu| [bu[:name], bu[:id]] }
      end

      def client_api_integration_report_categories
        @client_api_integration_report_categories ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'report_categories')
      end

      def client_api_integration_reports
        @client_api_integration_reports ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'reports')
      end

      def client_api_integration_scheduled_reports
        @client_api_integration_scheduled_reports ||= @client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'scheduled_reports')
      end

      def criteria_value(e_name, sub_e_name)
        @report&.dig(:criteria)&.dig(e_name.to_sym)&.dig(sub_e_name.to_sym)
      end

      def error_429_message(message)
        "ServiceTitan Rate Limit exceeded. Please try again after #{(Time.current + self.error_429_seconds(message).to_i.seconds).in_time_zone(@client.time_zone).strftime('%l:%M:%S %p').strip}."
      end

      def error_429_seconds(message)
        message.gsub(%r{[^\d]}, '')
      end

      def options_for_hour
        [
          ['Midnight', 0],
          ['1:00am', 1],
          ['2:00am', 2],
          ['3:00am', 3],
          ['4:00am', 4],
          ['5:00am', 5],
          ['6:00am', 6],
          ['7:00am', 7],
          ['8:00am', 8],
          ['9:00am', 9],
          ['10:00am', 10],
          ['11:00am', 11],
          ['Noon', 12],
          ['1:00pm', 13],
          ['2:00pm', 14],
          ['3:00pm', 15],
          ['4:00pm', 16],
          ['5:00pm', 17],
          ['6:00pm', 18],
          ['7:00pm', 19],
          ['8:00pm', 20],
          ['9:00pm', 21],
          ['10:00pm', 22],
          ['11:00pm', 23]
        ]
      end

      def options_for_report_dynamic_data_set(dynamic_set_id)
        @st_client.report_dynamic_data_set(dynamic_set_id).map(&:reverse)
      end

      def options_for_occurrences
        [
          ['1st of each Month', 1],
          ['2nd of each Month', 2],
          ['3rd of each Month', 3],
          ['4th of each Month', 4],
          ['5th of each Month', 5]
        ]
      end

      def report=(report)
        @report = report.deep_symbolize_keys
      end

      def report_campaign_id
        @report&.dig(:actions, :campaign_id).to_i
      end

      def report_category_id
        @report&.dig(:category_id).to_s
      end

      def report_data
        report_results&.dig(:data).presence || []
      end

      def report_field_data_type(name)
        @report.dig(:st_report, :fields)&.find { |f| f[:name] == name }&.dig(:dataType).presence || 'String'
      end

      def report_fields
        report_results&.dig(:fields).presence || []
      end

      def report_group
        @client.groups.find_by(id: self.report_group_id) || @client.groups.new
      end

      def report_group_id
        @report&.dig(:actions, :group_id).to_i
      end

      def report_id
        @report&.dig(:id).to_s
      end

      def report_name
        @report&.dig(:name).to_s
      end

      def report_parameters
        (@report&.dig(:st_report, :parameters).presence || []).map(&:deep_symbolize_keys)
      end

      def report_report_id
        @report&.dig(:st_report, :id).to_s
      end

      def report_results
        if @report_results.nil?
          @report_results = @st_client.report_results(
            category:   @report.dig(:category_id),
            report_id:  @report.dig(:st_report, :id),
            page_size:  25_000,
            parameters: @st_model.report_parameters_for_request(@report)
          )

          if @st_client.success?
            @report_error   = nil
            @report_message = @st_client.message.presence
          else
            @report_error   = @st_client.error
            @report_message = @report_error == 429 ? self.error_429_message(@st_client.message.to_s.gsub(%r{[^\d]}, '')) : @st_client.message
          end
        end

        @report_results
      end

      def report_schedule_days
        @report&.dig(:schedule, :days)
      end

      def report_schedule_hour
        @report&.dig(:schedule, :hour)&.map { |t| Time.current.change(hour: t.to_i).in_time_zone(@client.time_zone).strftime('%k').to_i }
      end

      def report_schedule_occurrences
        @report&.dig(:schedule, :occurrence)
      end

      def report_stage_id
        @report&.dig(:actions, :stage_id).to_i
      end

      def report_stop_campaign_ids
        @report&.dig(:actions, :stop_campaign_ids)
      end

      def report_tag
        @client.tags.find_by(id: self.report_tag_id) || @client.tags.new
      end

      def report_tag_id
        @report&.dig(:actions, :tag_id).to_i
      end

      def result_field_type(position)
        # self.report_fields[position]&.dig('dataType')
        report_field_data_type(report_fields[position]&.dig(:name))
      end

      def reports
        client_api_integration_scheduled_reports.data&.map(&:deep_symbolize_keys) || []
      end

      def reports_by_category(st_category_id)
        client_api_integration_reports.data.dig(st_category_id.to_s, 'reports')&.map { |c| [c.dig('name'), c.dig('id')] } || []
      end

      def reports_category_options
        client_api_integration_report_categories.data.map { |c| [c.dig('name'), c.dig('id')] }
      end

      def servicetitan_business_units
        @servicetitan_business_units ||= @st_model.business_units.sort_by { |e| e[0] }
      end

      def sorted_reports
        self.reports.sort_by { |r| r.dig(:name) }
      end
    end
  end
end
