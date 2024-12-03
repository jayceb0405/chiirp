# frozen_string_literal: true

# app/models/Integration/servicetitan/v2/reports/base.rb
module Integration
  module Servicetitan
    module V2
      module Reports
        module Base
          include Servicetitan::V2::Reports::Categories
          include Servicetitan::V2::Reports::Reports

          # create Array of parameters to submit to ServiceTitan API for report
          # st_model.report_parameters_for_request()
          #   (req) repport: (Hash)
          def report_parameters_for_request(report)
            response = []

            return response unless report.is_a?(Hash) || report.is_a?(ActiveSupport::HashWithIndifferentAccess)

            report = report.deep_symbolize_keys

            (report.dig(:criteria) || {}).to_h.each do |k, v|
              case v.dig(:data_type).to_s.downcase
              when 'boolean'
                response << { name: k, value: v.dig(:boolean).to_bool }
              when 'date'
                response << if v.dig(:days).present? && v.dig(:direction).casecmp?('past')
                              { name: k, value: (Date.current - v.dig(:days).to_i.days).iso8601 }
                            elsif v.dig(:days).present? && v.dig(:direction).casecmp?('future')
                              { name: k, value: (Date.current + v.dig(:days).to_i.days).iso8601 }
                            else
                              {}
                            end
              when 'number'
                response << if v.dig(:number).present?
                              { name: k, value: v.dig(:number) }
                            else
                              {}
                            end
              when 'string'
                response << if v.dig(:string).present?
                              { name: k, value: v.dig(:string) }
                            else
                              {}
                            end
              when 'time'
                response << if v.dig(:time).present? && v.dig(:direction).casecmp?('past')
                              { name: k, value: (Time.current - v.dig(:days).to_i.days).change({ hour: v.dig(:time).split(':').first.to_i, min: v.dig(:time).split(':').second.to_i, sec: v.dig(:time).split(':').third.to_i }).iso8601 }
                            elsif v.dig(:time).present? && v.dig(:direction).casecmp?('future')
                              { name: k, value: (Time.current + v.dig(:days).to_i.days).change({ hour: v.dig(:time).split(':').first.to_i, min: v.dig(:time).split(':').second.to_i, sec: v.dig(:time).split(':').third.to_i }).iso8601 }
                            else
                              {}
                            end
              end
            end

            response.compact_blank
          end
        end
      end
    end
  end
end
