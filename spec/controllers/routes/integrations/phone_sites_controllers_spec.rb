# /Users/Kevin/Rails Projects/funyl/spec/controllers/integrations/phone_sites_controllers_spec.rb
# foreman run bundle exec rspec spec/controllers/integrations/phone_sites_controllers_spec.rb
require 'rails_helper'

#                   edit_integrations_phone_sites_integration GET    /integrations/phone_sites/integration/edit(.:format)            integrations/phone_sites/integrations#edit
#                        integrations_phone_sites_integration GET    /integrations/phone_sites/integration(.:format)                 integrations/phone_sites/integrations#show
#                                                             DELETE /integrations/phone_sites/integration(.:format)                 integrations/phone_sites/integrations#destroy
#                                                             POST   /integrations/phone_sites/integration(.:format)                 integrations/phone_sites/integrations#create
#               integrations_phone_sites_integration_endpoint GET    /integrations/phone_sites/integration/endpoint(.:format)        integrations/phone_sites/integrations#endpoint
#                                                             POST   /integrations/phone_sites/integration/endpoint(.:format)        integrations/phone_sites/integrations#endpoint
#             integrations_phone_sites_integration_forms_edit GET    /integrations/phone_sites/integration/forms(.:format)           integrations/phone_sites/integrations#edit_forms
#           integrations_phone_sites_integration_forms_update POST   /integrations/phone_sites/integration/forms(.:format)           integrations/phone_sites/integrations#update_forms
#           integrations_phone_sites_integration_instructions GET    /integrations/phone_sites/integration/instructions(.:format)    integrations/phone_sites/integrations#instructions

describe "routing to PhoneSites" do
  it "routes (GET) /integrations/phone_sites/integration/edit to integrations/phone_sites/integrations#edit" do
    expect(get: "/integrations/phone_sites/integration/edit").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "edit"
    )
  end

  it "routes (GET) /integrations/phone_sites/integration to integrations/phone_sites/integrations#show" do
    expect(get: "/integrations/phone_sites/integration").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "show"
    )
  end

  it "routes (DELETE) /integrations/phone_sites/integration to integrations/phone_sites/integrations#destroy" do
    expect(delete: "/integrations/phone_sites/integration").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "destroy"
    )
  end

  it "routes (POST) /integrations/phone_sites/integration to integrations/phone_sites/integrations#create" do
    expect(post: "/integrations/phone_sites/integration").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "create"
    )
  end

  it "routes (GET) /integrations/phone_sites/integration/endpoint to integrations/phone_sites/integrations#endpoint" do
    expect(get: "/integrations/phone_sites/integration/endpoint").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "endpoint"
    )
  end

  it "routes (POST) /integrations/phone_sites/integration/endpoint to integrations/phone_sites/integrations#endpoint" do
    expect(post: "/integrations/phone_sites/integration/endpoint").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "endpoint"
    )
  end

  it "routes (GET) /integrations/phone_sites/integration/forms to integrations/phone_sites/integrations#edit_forms" do
    expect(get: "/integrations/phone_sites/integration/forms").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "edit_forms"
    )
  end

  it "routes (POST) /integrations/phone_sites/integration/forms to integrations/phone_sites/integrations#update_forms" do
    expect(post: "/integrations/phone_sites/integration/forms").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "update_forms"
    )
  end

  it "routes (GET) /integrations/phone_sites/integration/instructions to integrations/phone_sites/integrations#instructions" do
    expect(get: "/integrations/phone_sites/integration/instructions").to route_to(
      controller: "integrations/phone_sites/integrations",
      action: "instructions"
    )
  end
end
