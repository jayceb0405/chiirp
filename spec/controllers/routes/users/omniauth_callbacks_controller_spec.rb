# /Users/Kevin/Rails Projects/funyl/spec/controllers/users/omniauth_callbacks_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/users/omniauth_callbacks_controller_spec.rb
require 'rails_helper'
#             user_facebook_omniauth_authorize GET|POST /users/auth/facebook(.:format)                      users/omniauth_callbacks#passthru
#              user_facebook_omniauth_callback GET|POST /users/auth/facebook/callback(.:format)             users/omniauth_callbacks#facebook
# user_google_oauth2_chiirp_omniauth_authorize GET|POST /users/auth/google_oauth2_chiirp(.:format)          users/omniauth_callbacks#passthru
#  user_google_oauth2_chiirp_omniauth_callback GET|POST /users/auth/google_oauth2_chiirp/callback(.:format) users/omniauth_callbacks#google_oauth2_chiirp
#      user_outreach_chiirp_omniauth_authorize GET|POST /users/auth/outreach_chiirp(.:format)               users/omniauth_callbacks#passthru
#       user_outreach_chiirp_omniauth_callback GET|POST /users/auth/outreach_chiirp/callback(.:format)      users/omniauth_callbacks#outreach_chiirp
#         user_slack_chiirp_omniauth_authorize GET|POST /users/auth/slack_chiirp(.:format)                  users/omniauth_callbacks#passthru
#          user_slack_chiirp_omniauth_callback GET|POST /users/auth/slack_chiirp/callback(.:format)         users/omniauth_callbacks#slack_chiirp

describe 'routing to Users > OmniAuth Callbacks Controller' do
  it 'routes /users/auth/facebook to users/omniauth_callbacks#passthru' do
    expect(get: '/users/auth/facebook').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/facebook to users/omniauth_callbacks#passthru' do
    expect(post: '/users/auth/facebook').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/facebook/callback to users/omniauth_callbacks#facebook' do
    expect(get: '/users/auth/facebook/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'facebook'
    )
  end

  it 'routes /users/auth/facebook/callback to users/omniauth_callbacks#facebook' do
    expect(post: '/users/auth/facebook/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'facebook'
    )
  end

  it 'routes /users/auth/google_oauth2_chiirp to users/omniauth_callbacks#passthru' do
    expect(get: '/users/auth/google_oauth2_chiirp').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/google_oauth2_chiirp to users/omniauth_callbacks#passthru' do
    expect(post: '/users/auth/google_oauth2_chiirp').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/google_oauth2_chiirp/callback to users/omniauth_callbacks#google_oauth2_chiirp' do
    expect(get: '/users/auth/google_oauth2_chiirp/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'google_oauth2_chiirp'
    )
  end

  it 'routes /users/auth/google_oauth2_chiirp/callback to users/omniauth_callbacks#google_oauth2_chiirp' do
    expect(post: '/users/auth/google_oauth2_chiirp/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'google_oauth2_chiirp'
    )
  end

  it 'routes /users/auth/outreach_chiirp to users/omniauth_callbacks#passthru' do
    expect(get: '/users/auth/outreach_chiirp').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/outreach_chiirp to users/omniauth_callbacks#passthru' do
    expect(post: '/users/auth/outreach_chiirp').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/outreach_chiirp/callback to users/omniauth_callbacks#outreach_chiirp' do
    expect(get: '/users/auth/outreach_chiirp/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'outreach_chiirp'
    )
  end

  it 'routes /users/auth/outreach_chiirp/callback to users/omniauth_callbacks#outreach_chiirp' do
    expect(post: '/users/auth/outreach_chiirp/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'outreach_chiirp'
    )
  end

  it 'routes /users/auth/slack_chiirp to users/omniauth_callbacks#passthru' do
    expect(get: '/users/auth/slack_chiirp').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/slack_chiirp to users/omniauth_callbacks#passthru' do
    expect(post: '/users/auth/slack_chiirp').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'passthru'
    )
  end

  it 'routes /users/auth/slack_chiirp/callback to users/omniauth_callbacks#slack_chiirp' do
    expect(get: '/users/auth/slack_chiirp/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'slack_chiirp'
    )
  end

  it 'routes /users/auth/slack_chiirp/callback to users/omniauth_callbacks#slack_chiirp' do
    expect(post: '/users/auth/slack_chiirp/callback').to route_to(
      controller: 'users/omniauth_callbacks',
      action:     'slack_chiirp'
    )
  end
end
