# /Users/Kevin/Rails Projects/funyl/spec/controllers/integrations/jotform_controllers_spec.rb
# foreman run bundle exec rspec spec/controllers/routes/integrations/jotform_controllers_spec.rb
require 'rails_helper'

#                      integrations_jotform GET   /integrations/jotform(.:format)                      integrations/jotform/integrations#show
# integrations_jotform_integration_endpoint GET   /integrations/jotform/integration/endpoint(.:format) integrations/jotform/integrations#endpoint
#                                           POST  /integrations/jotform/integration/endpoint(.:format) integrations/jotform/integrations#endpoint
#       integrations_jotform_v1_connections GET   /integrations/jotform/v1/connections(.:format)       integrations/jotform/v1/connections#show
#                                           POST  /integrations/jotform/v1/connections(.:format)       integrations/jotform/v1/connections#create
#             integrations_jotform_v1_forms GET   /integrations/jotform/v1/forms(.:format)             integrations/jotform/v1/forms#show
#                                           PATCH /integrations/jotform/v1/forms(.:format)             integrations/jotform/v1/forms#update
#                                           PUT   /integrations/jotform/v1/forms(.:format)             integrations/jotform/v1/forms#update
#      integrations_jotform_v1_instructions GET   /integrations/jotform/v1/instructions(.:format)      integrations/jotform/v1/instructions#show
#                   integrations_jotform_v1 GET   /integrations/jotform/v1(.:format)                   integrations/jotform/v1/integrations#show
#     integrations_jotform_v1_subscriptions PATCH /integrations/jotform/v1/subscriptions(.:format)     integrations/jotform/v1/subscriptions#update
#                                           PUT   /integrations/jotform/v1/subscriptions(.:format)     integrations/jotform/v1/subscriptions#update

describe 'routing to Jotform' do
  it 'routes (GET) /integrations/jotform to integrations/jotform/integrations#show' do
    expect(get: '/integrations/jotform').to route_to(
      controller: 'integrations/jotform/integrations',
      action:     'show'
    )
  end

  it 'routes (GET) /integrations/jotform/integration/endpoint to integrations/jotform/integrations#endpoint' do
    expect(get: '/integrations/jotform/integration/endpoint').to route_to(
      controller: 'integrations/jotform/integrations',
      action:     'endpoint'
    )
  end

  it 'routes (POST) /integrations/jotform/integration/endpoint to integrations/jotform/integrations#endpoint' do
    expect(post: '/integrations/jotform/integration/endpoint').to route_to(
      controller: 'integrations/jotform/integrations',
      action:     'endpoint'
    )
  end

  it 'routes (GET) /integrations/jotform/v1/connections to integrations/jotform/v1/connections#show' do
    expect(get: '/integrations/jotform/v1/connections').to route_to(
      controller: 'integrations/jotform/v1/connections',
      action:     'show'
    )
  end

  it 'routes (POST) /integrations/jotform/v1/connections to integrations/jotform/v1/connections#create' do
    expect(post: '/integrations/jotform/v1/connections').to route_to(
      controller: 'integrations/jotform/v1/connections',
      action:     'create'
    )
  end

  it 'routes (GET) /integrations/jotform/v1/forms to integrations/jotform/v1/forms#show' do
    expect(get: '/integrations/jotform/v1/forms').to route_to(
      controller: 'integrations/jotform/v1/forms',
      action:     'show'
    )
  end

  it 'routes (PUT) /integrations/jotform/v1/forms to integrations/jotform/v1/forms#update' do
    expect(put: '/integrations/jotform/v1/forms').to route_to(
      controller: 'integrations/jotform/v1/forms',
      action:     'update'
    )
  end

  it 'routes (PATCH) /integrations/jotform/v1/forms to integrations/jotform/v1/forms#update' do
    expect(patch: '/integrations/jotform/v1/forms').to route_to(
      controller: 'integrations/jotform/v1/forms',
      action:     'update'
    )
  end

  it 'routes (GET) /integrations/jotform/v1/instructions to integrations/jotform/v1/instructions#show' do
    expect(get: '/integrations/jotform/v1/instructions').to route_to(
      controller: 'integrations/jotform/v1/instructions',
      action:     'show'
    )
  end

  it 'routes (GET) /integrations/jotform/v1 to integrations/jotform/v1/integrations#show' do
    expect(get: '/integrations/jotform/v1').to route_to(
      controller: 'integrations/jotform/v1/integrations',
      action:     'show'
    )
  end

  it 'routes (PUT) /integrations/jotform/v1/subscriptions to integrations/jotform/v1/subscriptions#update' do
    expect(put: '/integrations/jotform/v1/subscriptions').to route_to(
      controller: 'integrations/jotform/v1/subscriptions',
      action:     'update'
    )
  end

  it 'routes (PATCH) /integrations/jotform/v1/subscriptions to integrations/jotform/v1/subscriptions#update' do
    expect(patch: '/integrations/jotform/v1/subscriptions').to route_to(
      controller: 'integrations/jotform/v1/subscriptions',
      action:     'update'
    )
  end
end
