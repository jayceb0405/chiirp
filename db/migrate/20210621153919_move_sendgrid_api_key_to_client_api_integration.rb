class MoveSendgridApiKeyToClientApiIntegration < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving SendGrid API Key from Client table to ClientApiIntegration table...' do
      
      Client.where("data -> 'sendgrid_api_key' != ?", ''.to_json).find_each do |client|
        
        if (client_api_integration = ClientApiIntegration.find_or_initialize_by(client_id: client.id, target: 'sendgrid'))
          client_api_integration.update(api_key: client.data.dig('sendgrid_api_key').to_s, created_at: Time.current, updated_at: Time.current)
        end

        client.data.delete('sendgrid_api_key')
        client.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving SendGrid API Key from ClientApiIntegration table to Client table...' do
      
      ClientApiIntegration.where(target: 'sendgrid').find_each do |client_api_integration|

        if (client = Client.find_by(id: client_api_integration.client_id))
          client.data['sendgrid_api_key'] = client_api_integration.api_key
          client.save
        end

        client_api_integration.destroy
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
