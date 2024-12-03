class MoveGoogleReviewsToClientApiIntegration < ActiveRecord::Migration[7.0]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving Google Reviews from UserApiIntegration to ClientApiIntegration...' do

      UserApiIntegration.where(target: 'google', name: '').find_each do |user_api_integration|

        if user_api_integration.data.dig('reviews', 'active_accounts').present?

          if (client_api_integration = user_api_integration.user.client.client_api_integrations.find_or_create_by(target: 'google', name: 'reviews', created_at: Time.current, updated_at: Time.current))
            client_api_integration.update(
              data: {
                actions:          user_api_integration.data.dig('reviews', 'actions') || {},
                active_accounts:  user_api_integration.data.dig('reviews', 'active_accounts') || [],
                active_locations: user_api_integration.data.dig('reviews', 'active_locations') || {},
                last_start_date:  user_api_integration.data.dig('reviews', 'last_start_date').to_s,
                reviews_links:    user_api_integration.data.dig('reviews', 'reviews_links') || {},
                user_id:          user_api_integration.user_id
              }
            )
          end
        end

        user_api_integration.data.delete('reviews')
        user_api_integration.save
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Moving Google Reviews from ClientApiIntegration to UserApiIntegration...' do

      ClientApiIntegration.where(target: 'google', name: 'reviews').find_each do |client_api_integration|

        if (user_api_integration = UserApiIntegration.find_or_create_by(user_id: client_api_integration.data.dig('user_id'), target: 'google', name: ''))
          user_api_integration.data['reviews'] = {
            actions:          client_api_integration.data.dig('actions') || {},
            active_accounts:  client_api_integration.data.dig('active_accounts') || [],
            active_locations: client_api_integration.data.dig('active_locations') || {},
            last_start_date:  client_api_integration.data.dig('last_start_date').to_s,
            reviews_links:    client_api_integration.data.dig('reviews_links') || {}
          }
          user_api_integration.save
        end

        client_api_integration.destroy
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
