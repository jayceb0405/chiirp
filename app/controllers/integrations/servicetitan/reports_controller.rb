# frozen_string_literal: true

# app/controllers/integrations/servicetitan/reports_controller.rb
module Integrations
  module Servicetitan
    class ReportsController < Servicetitan::IntegrationsController
      before_action :report, only: %i[destroy edit refresh_report_categories refresh_reports update update_report_criteria update_report_reports]

      # (DELETE) destroy a Report
      # /integrations/servicetitan/reports/:id
      # integrations_servicetitan_report_path(:id)
      # integrations_servicetitan_report_url(:id)
      def destroy
        client_api_integration_scheduled_reports.data.delete(@report.deep_stringify_keys)
        client_api_integration_scheduled_reports.save
      end

      # (GET) show api_key edit screen
      # /integrations/servicetitan/reports/:id/edit
      # edit_integrations_servicetitan_report_path(:id)
      # edit_integrations_servicetitan_report_url(:id)
      def edit
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_report_categories if client_api_integration_report_categories.data.blank?

        return unless @report.dig('st_report', 'id').present? && @report.dig('st_report', 'fields').blank?

        @report['st_report'] = refresh_report(@report.dig('category_id'), @report.dig('st_report', 'id'))
        client_api_integration_scheduled_reports.save
      end

      # (GET) display a new Push Contact Tag
      # /integrations/servicetitan/reports/new
      # new_integrations_servicetitan_report_path
      # new_integrations_servicetitan_report_url
      def new
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_report_categories if client_api_integration_report_categories.data.blank?
        @report = {
          id:          SecureRandom.uuid,
          name:        'New Report',
          category_id: client_api_integration_report_categories.data.first&.dig('id')
        }
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_reports(st_report_category_id: @report.dig(:category_id)) if client_api_integration_reports.data.dig(@report.dig(:category_id)).blank?
        client_api_integration_scheduled_reports.update(data: (client_api_integration_scheduled_reports.data ||= []).to_a << @report)
      end

      # (GET) display the list of Push Contacts Tags
      # /integrations/servicetitan/reports
      # integrations_servicetitan_reports_path
      # integrations_servicetitan_reports_url
      def index; end

      # (GET) refresh ST report categories
      # /integrations/servicetitan/reports/refresh_report_categories
      # integrations_servicetitan_reports_refresh_report_categories_path
      # integrations_servicetitan_reports_refresh_report_categories_url
      def refresh_report_categories
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_report_categories
      end

      # (GET) refresh ST reports for a specific category
      # /integrations/servicetitan/reports/refresh_reports
      # integrations_servicetitan_reports_refresh_reports_path
      # integrations_servicetitan_reports_refresh_reports_url
      def refresh_reports
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_reports(st_report_category_id: @report.dig('category_id'))
      end

      # (PATCH/PUT) update api_key
      # /integrations/servicetitan/reports/:id
      # integrations_servicetitan_report_path(:id)
      # integrations_servicetitan_report_url(:id)
      def update
        sanitized_params = params_report
        @report[:category_id] = sanitized_params.dig(:category_id)
        @report[:name]        = sanitized_params.dig(:name)
        @report[:criteria]    = sanitized_params.dig(:criteria)
        @report[:actions]     = sanitized_params.dig(:actions)
        @report[:schedule]    = sanitized_params.dig(:schedule)
        client_api_integration_scheduled_reports.save

        if params.dig(:commit).casecmp?('Save Report & Show Results')
          respond_to do |format|
            format.turbo_stream { render 'integrations/servicetitan/reports/report_results' }
          end
        elsif params.dig(:commit).casecmp?('Save Report & Process Results')
          Integrations::Servicetitan::V2::Reports::ResultsClientJob.perform_later(client_id: @client_api_integration.client_id, report: @report)
        end
      end

      # (GET) update report criteria for selected report
      # /integrations/servicetitan/reports/update_report_criteria/:id
      # integrations_servicetitan_update_report_criteria_path(:id)
      # integrations_servicetitan_update_report_criteria_url(:id)
      #   (req) st_category_id: (String)
      #   (req) st_report_id:   (Integer)
      def update_report_criteria
        @report['category_id'] = params.permit(:st_category_id).dig(:st_category_id).to_s
        @report['st_report']   = refresh_report(@report['category_id'], params.permit(:st_report_id).dig(:st_report_id).to_i)
        client_api_integration_scheduled_reports.save
      end

      # (GET) update reports select options for selected category
      # /integrations/servicetitan/reports/update_report_reports/:id
      # integrations_servicetitan_update_report_reports_path(:id)
      # integrations_servicetitan_update_report_reports_url(:id)
      def update_report_reports
        @report['category_id'] = params.permit(:st_category_id).dig(:st_category_id).to_s
        client_api_integration_scheduled_reports.save
        Integration::Servicetitan::V2::Base.new(@client_api_integration).refresh_reports(st_report_category_id: params.dig(:st_category_id).to_s) if client_api_integration_reports.data.dig(params.dig(:st_category_id).to_s, 'reports').blank?
      end

      private

      def client_api_integration_report_categories
        @client_api_integration_report_categories = current_user.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'report_categories')
      end

      def client_api_integration_reports
        @client_api_integration_reports ||= current_user.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'reports')
      end

      def client_api_integration_scheduled_reports
        @client_api_integration_scheduled_reports ||= current_user.client.client_api_integrations.find_or_create_by(target: 'servicetitan', name: 'scheduled_reports')
      end

      def params_report
        sanitized_params = params.require(:report).permit(:category_id, :name, criteria: {}, actions: %i[campaign_id group_id stage_id tag_id] + [{ stop_campaign_ids: [] }], schedule: {})

        sanitized_params[:id] = params.permit(:id).dig(:id).to_s

        sanitized_params.dig(:criteria).to_h.each do |k, v|
          if v.dig('data_type').casecmp?('number')
            if v.dig('number').is_a?(Array)
              sanitized_params['criteria'][k]['number'] = v.dig('number').compact_blank.map(&:to_i)
            else
              v.dig('number').is_a?(String)
              sanitized_params['criteria'][k]['number'] = v.dig('number').include?('.') ? v.dig('number').to_d : v.dig('number').to_i
            end
          end
        end

        sanitized_params['actions'] = {
          campaign_id:       sanitized_params.dig('actions', 'campaign_id').to_i,
          group_id:          sanitized_params.dig('actions', 'group_id').to_i,
          stage_id:          sanitized_params.dig('actions', 'stage_id').to_i,
          tag_id:            sanitized_params.dig('actions', 'tag_id').to_i,
          stop_campaign_ids: [sanitized_params.dig('actions', 'stop_campaign_ids')].flatten.compact_blank
        }
        sanitized_params['actions']['stop_campaign_ids'] = [0] if sanitized_params.dig('actions', 'stop_campaign_ids')&.include?('0')
        sanitized_params['schedule']                     = {
          days:       [sanitized_params.dig('schedule', 'days')].flatten.compact_blank,
          occurrence: [sanitized_params.dig('schedule', 'occurrence')].flatten.compact_blank.map(&:to_i),
          hour:       [sanitized_params.dig('schedule', 'hour')].flatten.compact_blank.map { |t| Time.current.in_time_zone(@client_api_integration.client.time_zone).change(hour: t.to_i).utc.strftime('%k').to_i }
        }

        sanitized_params.to_unsafe_hash.deep_symbolize_keys
      end
      # example raw params
      # {
      #   authenticity_token: '[FILTERED]',
      #   report:             { name:        'New Report',
      #                         category_id: 'marketing',
      #                         criteria:    { From:            { data_type: 'Date', direction: 'past', days: '15' },
      #                                        To:              { data_type: 'Date', direction: 'future', days: '0' },
      #                                        IncludeInactive: { data_type: 'Boolean', boolean: 'false' },
      #                                        BusinessUnitIds: { data_type: 'Number', number: [''] } },
      #                         actions:     { campaign_id: '', group_id: '', tag_id: '', stage_id: '', stop_campaign_ids: [''] },
      #                         schedule:    { days: [''], occurrence: [''], hour: '20' } },
      #   group:              { 'report[actions': { group_id: { '][name]': '' } } },
      #   tag:                { 'report[actions': { tag_id: { '][name]': '' } } },
      #   commit:             'Save Report',
      #   id:                 '2cc907da-0307-4b11-8b18-58a0e1aaf31e'
      # }
      # example sanitized params
      # {
      #   category_id: 'marketing',
      #   name:        'New Report',
      #   criteria:    { From:            { data_type: 'Date', direction: 'past', days: '15' },
      #                  To:              { data_type: 'Date', direction: 'future', days: '0' },
      #                  IncludeInactive: { data_type: 'Boolean', boolean: 'false' },
      #                  BusinessUnitIds: { data_type: 'Number', number: [] } },
      #   actions:     { campaign_id: 0, group_id: 0, stage_id: 0, tag_id: 0, stop_campaign_ids: [] },
      #   schedule:    { days: [], occurrence: [], hour: '20' },
      #   id:          '2cc907da-0307-4b11-8b18-58a0e1aaf31e'
      # }

      def refresh_report(st_category_id, st_report_id)
        return unless (st_model = Integration::Servicetitan::V2::Base.new(@client_api_integration)) && st_model.valid_credentials? &&
                      (st_client = Integrations::ServiceTitan::Base.new(@client_api_integration.credentials))

        st_client.report(category_id: st_category_id, report_id: st_report_id)
      end

      def report
        return if (@report = client_api_integration_scheduled_reports.data.find { |report| report.dig('id') == params.permit(:id).dig(:id).to_s })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end
    end
  end
end
