class ConvertServicetitanJobActions < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing ClientApiIntegration table...' do

      ClientApiIntegration.where(target: 'servicetitan', name: '').find_each do |client_api_integration|
        client_api_integration.events  = client_api_integration.data.dig('job_actions', 'actions')
        client_api_integration.reviews = client_api_integration.data.dig('job_actions', 'reviews').merge({ update_review_window_hours: client_api_integration.data.dig('job_actions', 'update_review_window_hours') })
        client_api_integration.data.delete('job_actions')
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
