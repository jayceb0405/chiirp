class ServiceTitanReportHour < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating "Hour" in ServoceTitan Report Criteria...' do
      ClientApiIntegration.where(target: 'servicetitan', name: 'scheduled_reports').find_each do |client_api_integration|
        client_api_integration.data.each do |report|
          report['schedule']['hour'] = [report.dig('schedule', 'hour')].flatten.compact_blank if report.dig('schedule', 'hour').present?
        end

        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
