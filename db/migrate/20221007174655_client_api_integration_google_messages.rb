class ClientApiIntegrationGoogleMessages < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Updating ClientApiIntegration table...' do

      ClientApiIntegration.where(target: 'google', name: 'reviews').find_each do |client_api_integration|
        client_api_integration.name                              = ''
        client_api_integration.data['actions_reviews']           = client_api_integration.data.dig('actions') || {}
        client_api_integration.data['actions_messages']          = {}
        client_api_integration.data['active_locations_reviews']  = client_api_integration.data.dig('active_locations') || {}
        client_api_integration.data['active_locations_messages'] = {}
        client_api_integration.data.delete('actions')
        client_api_integration.data.delete('active_locations')
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Updating ClientApiIntegration table...' do

      ClientApiIntegration.where(target: 'google', name: '').find_each do |client_api_integration|
        client_api_integration.name                              = 'reviews'
        client_api_integration.data['actions']                   = client_api_integration.data.dig('actions_reviews') || {}
        client_api_integration.data['active_locations']          = client_api_integration.data.dig('active_locations_reviews') || {}
        client_api_integration.data.delete('actions_messages')
        client_api_integration.data.delete('actions_reviews')
        client_api_integration.data.delete('active_locations_messages')
        client_api_integration.data.delete('active_locations_reviews')
        client_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
