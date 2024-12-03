class ConvertHousecallProCredentials < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Converting Housecall Pro credentials in ClientApiIntegration table...' do
      ClientApiIntegration.where(target: 'housecall', name: '').find_each do |client_api_integration|
        client_api_integration.credentials = { access_token: '', access_token_expires_at: 0, refresh_token: client_api_integration.data.dig('refresh_token').to_s }
        client_api_integration.data.delete('refresh_token')
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
