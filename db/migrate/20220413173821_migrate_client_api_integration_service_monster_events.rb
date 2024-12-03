class MigrateClientApiIntegrationServiceMonsterEvents < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating ServiceMonster events in ClientApiIntegration model...' do
      ClientApiIntegration.where(target: 'servicemonster', name: '').find_each do |client_api_integration|
        client_api_integration.migrate_servicemonster_events
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
