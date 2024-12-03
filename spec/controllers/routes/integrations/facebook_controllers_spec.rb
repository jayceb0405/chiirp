# /Users/Kevin/Rails Projects/funyl/spec/controllers/integrations/facebook_controllers_spec.rb
# foreman run bundle exec rspec spec/controllers/integrations/facebook_controllers_spec.rb
require 'rails_helper'
#                      facebook_endpoint GET    /facebook/endpoint(.:format)                          integrations/facebook/integrations#endpoint
#                                        POST   /facebook/endpoint(.:format)                          integrations/facebook/integrations#endpoint
#                      facebook_webhooks GET    /facebook/webhooks(.:format)                          integrations/facebook/integrations#endpoint
#                                        POST   /facebook/webhooks(.:format)                          integrations/facebook/integrations#endpoint
#                      facebook_platform GET    /facebook/platform(.:format)                          integrations/facebook/integrations#platform
#                     facebook_logintest GET    /facebook/logintest(.:format)                         integrations/facebook/integrations#logintest
#                 facebook_longlivetoken GET    /facebook/longlivetoken(.:format)                     integrations/facebook/integrations#longlivetoken
# edit_integrations_facebook_connections GET    /integrations/facebook/connections/edit(.:format)     integrations/facebook/connections#edit
#      integrations_facebook_connections PATCH  /integrations/facebook/connections(.:format)          integrations/facebook/connections#update
#                                        PUT    /integrations/facebook/connections(.:format)          integrations/facebook/connections#update
#                                        DELETE /integrations/facebook/connections(.:format)          integrations/facebook/connections#destroy
#     integrations_facebook_instructions GET    /integrations/facebook/instructions(.:format)         integrations/facebook/instructions#show
#      integrations_facebook_integration GET    /integrations/facebook/integration(.:format)          integrations/facebook/integrations#show
#            integrations_facebook_pages GET    /integrations/facebook/pages(.:format)                integrations/facebook/pages#index
#             integrations_facebook_page PATCH  /integrations/facebook/pages/:id(.:format)            integrations/facebook/pages#update
#                                        PUT    /integrations/facebook/pages/:id(.:format)            integrations/facebook/pages#update
#      integrations_facebook_leads_forms GET    /integrations/facebook/leads/forms(.:format)          integrations/facebook/leads/forms#index
#  edit_integrations_facebook_leads_form GET    /integrations/facebook/leads/forms/:id/edit(.:format) integrations/facebook/leads/forms#edit
#       integrations_facebook_leads_form PATCH  /integrations/facebook/leads/forms/:id(.:format)      integrations/facebook/leads/forms#update
#                                        PUT    /integrations/facebook/leads/forms/:id(.:format)      integrations/facebook/leads/forms#update
#  integrations_facebook_messenger_pages GET    /integrations/facebook/messenger/pages(.:format)      integrations/facebook/messenger/pages#index

describe "routing to Integrations > Facebook > Integrations Controller" do
  it "routes facebook/endpoint to integrations/facebook/integrations#endpoint" do
    expect(get: "facebook/endpoint").to route_to(
      controller: "integrations/facebook/integrations",
      action: "endpoint"
    )
  end

  it "routes facebook/endpoint to integrations/facebook/integrations#endpoint" do
    expect(post: "facebook/endpoint").to route_to(
      controller: "integrations/facebook/integrations",
      action: "endpoint"
    )
  end

  it "routes facebook/webhooks to integrations/facebook/integrations#endpoint" do
    expect(get: "facebook/webhooks").to route_to(
      controller: "integrations/facebook/integrations",
      action: "endpoint"
    )
  end

  it "routes facebook/webhooks to integrations/facebook/integrations#endpoint" do
    expect(post: "facebook/webhooks").to route_to(
      controller: "integrations/facebook/integrations",
      action: "endpoint"
    )
  end

  it "routes facebook/platform to integrations/facebook/integrations#platform" do
    expect(get: "facebook/platform").to route_to(
      controller: "integrations/facebook/integrations",
      action: "platform"
    )
  end

  it "routes facebook/logintest to integrations/facebook/integrations#logintest" do
    expect(get: "facebook/logintest").to route_to(
      controller: "integrations/facebook/integrations",
      action: "logintest"
    )
  end

  it "routes facebook/longlivetoken to integrations/facebook/integrations#longlivetoken" do
    expect(get: "facebook/longlivetoken").to route_to(
      controller: "integrations/facebook/integrations",
      action: "longlivetoken"
    )
  end

  it "routes /integrations/facebook/connections/edit to integrations/facebook/connections#edit" do
    expect(get: "integrations/facebook/connections/edit").to route_to(
      controller: "integrations/facebook/connections",
      action: "edit"
    )
  end

  it "routes /integrations/facebook/connections to integrations/facebook/connections#update" do
    expect(patch: "integrations/facebook/connections").to route_to(
      controller: "integrations/facebook/connections",
      action: "update"
    )
  end

  it "routes /integrations/facebook/connections to integrations/facebook/connections#update" do
    expect(put: "integrations/facebook/connections").to route_to(
      controller: "integrations/facebook/connections",
      action: "update"
    )
  end

  it "routes /integrations/facebook/connections to integrations/facebook/connections#destroy" do
    expect(delete: "integrations/facebook/connections").to route_to(
      controller: "integrations/facebook/connections",
      action: "destroy"
    )
  end

  it "routes /integrations/facebook/instructions to integrations/facebook/instructions#show" do
    expect(get: "integrations/facebook/instructions").to route_to(
      controller: "integrations/facebook/instructions",
      action: "show"
    )
  end

  it "routes /integrations/facebook/integration to integrations/facebook/integrations#show" do
    expect(get: "integrations/facebook/integration").to route_to(
      controller: "integrations/facebook/integrations",
      action: "show"
    )
  end

  it "routes /integrations/facebook/pages to integrations/facebook/pages#index" do
    expect(get: "integrations/facebook/pages").to route_to(
      controller: "integrations/facebook/pages",
      action: "index"
    )
  end

  it "routes /integrations/facebook/pages/:id to integrations/facebook/pages#update" do
    expect(patch: "integrations/facebook/pages/1").to route_to(
      controller: "integrations/facebook/pages",
      action: "update",
      id: "1"
    )
  end

  it "routes /integrations/facebook/pages/:id to integrations/facebook/pages#update" do
    expect(put: "integrations/facebook/pages/1").to route_to(
      controller: "integrations/facebook/pages",
      action: "update",
      id: "1"
    )
  end

  it "routes /integrations/facebook/leads/forms to integrations/facebook/leads/forms#index" do
    expect(get: "integrations/facebook/leads/forms").to route_to(
      controller: "integrations/facebook/leads/forms",
      action: "index"
    )
  end

  it "routes /integrations/facebook/leads/forms/:id/edit to integrations/facebook/leads/forms#edit" do
    expect(get: "integrations/facebook/leads/forms/1/edit").to route_to(
      controller: "integrations/facebook/leads/forms",
      action: "edit",
      id: "1"
    )
  end

  it "routes /integrations/facebook/leads/forms/:id to integrations/facebook/leads/forms#update" do
    expect(patch: "integrations/facebook/leads/forms/1").to route_to(
      controller: "integrations/facebook/leads/forms",
      action: "update",
      id: "1"
    )
  end

  it "routes /integrations/facebook/leads/forms/:id to integrations/facebook/leads/forms#update" do
    expect(put: "integrations/facebook/leads/forms/1").to route_to(
      controller: "integrations/facebook/leads/forms",
      action: "update",
      id: "1"
    )
  end

  it "routes /integrations/facebook/messenger/pages to integrations/facebook/messenger/pages#index" do
    expect(get: "integrations/facebook/messenger/pages").to route_to(
      controller: "integrations/facebook/messenger/pages",
      action: "index"
    )
  end
end
