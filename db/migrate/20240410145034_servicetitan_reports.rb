class ServicetitanReports < ActiveRecord::Migration[7.1]
  def change
    ClientApiIntegration.where(target: 'servicetitan', name: 'reports').each do |client_api_integration|
      client_api_integration.name = 'scheduled_reports'
      client_api_integration.data = client_api_integration.data.dig('reports').to_a

      client_api_integration.data.each do |report|
        report['criteria']  = report.dig('parameters')
        report['st_report'] = { 'id' => report.dig('report_id') }
        report.delete('parameters')
        report.delete('report_id')
      end

      client_api_integration.save
    end

    ClientApiIntegration.where(target: 'servicetitan', name: 'servicetitan_reports').update_all(name: 'reports')
  end
end
