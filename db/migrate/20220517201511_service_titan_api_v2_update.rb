class ServiceTitanApiV2Update < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating ClientApiIntegration model for ServiceTitan API v2 Integrations...' do

      ClientApiIntegration.where(target: 'servicetitan', name: '').find_each do |client_api_integration|
        client_api_integration.update(credentials: {
            client_id:     '',
            client_secret: '',
            tenant_id:     ''
          }
        )
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
