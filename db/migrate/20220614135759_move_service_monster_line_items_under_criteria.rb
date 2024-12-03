class MoveServiceMonsterLineItemsUnderCriteria < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving ServiceMonster Webhook Line Items under Criteria...' do
      ClientApiIntegration.where(target: 'servicemonster').find_each do |client_api_integration|

        client_api_integration.webhooks.each do |_webhook, events|

          events.dig('events').each do |event|

            if event.dig('line_items') && event.dig('criteria')
              event['criteria']['line_items'] = event['line_items']
              event.delete('line_items')
            end
          end
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

    say_with_time 'Moving ServiceMonster Webhook Line Items out from under Criteria...' do
      ClientApiIntegration.where(target: 'servicemonster').find_each do |client_api_integration|

        client_api_integration.webhooks.each do |_webhook, events|

          events.dig('events').each do |event|

            if event.dig('criteria', 'line_items')
              event['line_items'] = event['criteria']['line_items']
              event['criteria'].delete('line_items')
            end
          end
        end
        
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
