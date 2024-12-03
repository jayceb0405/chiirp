class MultiUserFacebookIntegration < ActiveRecord::Migration[6.1]
  def up
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Migrating UserApiIntegration data for Facebook Integration model...' do

      UserApiIntegration.where(target: 'facebook').find_each do |user_api_integration|

        if user_api_integration.data.dig('facebook_user_token').to_s.present?
          fb_client = Fb::Users.new(user_api_integration.data.dig('facebook_user_token').to_s)
          fb_client.user

          if fb_client.success?
            user_api_integration.data = {
              users: [{
                id: fb_client.result.dig(:id).to_s,
                name: fb_client.result.dig(:name).to_s,
                token: user_api_integration.data.dig('facebook_user_token').to_s
              }],
              forms: user_api_integration.data.dig('facebook_forms'),
              pages: user_api_integration.data.dig('facebook_pages'),
            }

            (user_api_integration.data.dig('forms') || []).each do |form|
              form[:user_id] = fb_client.result.dig(:id).to_s
            end

            (user_api_integration.data.dig('pages') || []).each do |page|
              page[:user_id] = fb_client.result.dig(:id).to_s
            end

            user_api_integration.save
          end
        else
          user_api_integration.update(data: {})
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end

  def down
    ActiveRecord::Base.record_timestamps = false
    say 'Turned off timestamps.'

    say_with_time 'Reverting UserApiIntegration data for Facebook Integration model...' do

      UserApiIntegration.where(target: 'facebook').find_each do |user_api_integration|
        user_api_integration.data.delete('expires_at')
        user_api_integration.data.delete('refresh_token')
        user_api_integration.data.delete('token')

        if user_api_integration.data.present?
          user_api_integration.update(data: {
            facebook_forms: user_api_integration.data.dig('forms'),
            facebook_pages: user_api_integration.data.dig('pages'),
            facebook_user_id: user_api_integration.data.dig('users').first.dig('id').to_s,
            facebook_user_token: user_api_integration.data.dig('users').first.dig('token').to_s
          })

          (user_api_integration.data.dig('facebook_forms') || []).each do |form|
            form.delete('user_id')
          end

          (user_api_integration.data.dig('facebook_pages') || []).each do |page|
            page.delete('user_id')
          end

          user_api_integration.save
        end
      end
    end

    ActiveRecord::Base.record_timestamps = true
    say 'Turned on timestamps.'
  end
end
