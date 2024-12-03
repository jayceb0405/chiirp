class MoveHouseCallProLineItemsUnderCriteria < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving Housecall Pro Webhook Line Items under Criteria...' do
      ClientApiIntegration.where(target: 'housecall').find_each do |client_api_integration|

        client_api_integration.webhooks.each do |_event, webhooks|

          webhooks.each do |webhook|

            if webhook.dig('line_items') && webhook.dig('criteria')
              webhook['criteria']['line_items'] = webhook['line_items']
              webhook.delete('line_items')
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

    say_with_time 'Moving Housecall Pro Webhook Line Items out from under Criteria...' do
      ClientApiIntegration.where(target: 'housecall').find_each do |client_api_integration|

        client_api_integration.webhooks.each do |_event, webhooks|

          webhooks.each do |webhook|

            if webhook.dig('criteria', 'line_items')
              webhook['line_items'] = webhook['criteria']['line_items']
              webhook['criteria'].delete('line_items')
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
