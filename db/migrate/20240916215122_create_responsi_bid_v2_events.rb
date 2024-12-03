class CreateResponsiBidV2Events < ActiveRecord::Migration[7.2]
  def change
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating ResponsiBid evemts to version 1 in ClientApiIntegration table...' do

      ClientApiIntegration.where(target: 'responsibid', name: '').where.not(api_key: '').each do |client_api_integration|
        client_api_integration.data.dig('webhooks')&.each_key do |webhook_key|

          client_api_integration.data.dig('webhooks', webhook_key)&.each do |webhook|
            webhook['version'] = 1
          end
        end

        client_api_integration.save
      end
    end
  end
end
