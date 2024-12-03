class ConvertServiceTitanTagIdsToTagIdsInclude < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing tag_ids in ClientApiIntegration to tag_ids_include for ServiceTitan integrations...' do

      ClientApiIntegration.where(target: 'servicetitan', name: '').each do |client_api_integration|

        client_api_integration.events.each do |_id, event|
          event['tag_ids_include'] = event.dig('tag_ids') || []
          event['tag_ids_exclude'] = []
          event.delete('tag_ids')
        end

        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Changing tag_ids_include in ClientApiIntegration to tag_ids for ServiceTitan integrations...' do

      ClientApiIntegration.where(target: 'servicetitan', name: '').each do |client_api_integration|

        client_api_integration.events.each do |_id, event|
          event['tag_ids'] = event.dig('tag_ids_include') || []
          event.delete('tag_ids_include')
          event.delete('tag_ids_exclude')
        end

        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
