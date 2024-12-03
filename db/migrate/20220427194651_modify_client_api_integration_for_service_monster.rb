class ModifyClientApiIntegrationForServiceMonster < ActiveRecord::Migration[7.0]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating ServiceMonster events in ClientApiIntegration model...' do
      ClientApiIntegration.where(target: 'servicemonster', name: '').find_each do |client_api_integration|
        client_api_integration.webhooks.each do |webhook|
          webhook.last.dig('events').each do |event|

            if !event.dig('criteria', 'residential').to_bool && !event.dig('criteria', 'commercial').to_bool
              event['criteria']['residential'] = true
              event['criteria']['commercial']  = true
            end

            if !event.dig('criteria', 'event_new').to_bool && !event.dig('criteria', 'event_updated').to_bool
              event['criteria']['event_new']      = true
              event['criteria']['event_updated']  = true
            end

            event['actions']['assign_user_to_technician'] = event.dig('actions', 'assign_user').to_bool
            event['actions']['assign_user_to_salesrep']   = false
            event['actions'].delete('assign_user')

            if webhook.first[0, 6] == 'order_'
              event['criteria']['order_groups']    = []
              event['criteria']['order_subgroups'] = []
            end
          end
        end

        client_api_integration.order_groups    = []
        client_api_integration.order_subgroups = []
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
