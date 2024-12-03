# /Users/Kevin/Rails Projects/funyl/spec/routing/clients/org_positions_spec.rb
# bundle exec rspec spec/routing/clients/org_positions_spec.rb
require 'rails_helper'

#     client_org_positions GET    /client/:client_id/org_positions(.:format)          clients/org_positions#index
#                          POST   /client/:client_id/org_positions(.:format)          clients/org_positions#create
#  new_client_org_position GET    /client/:client_id/org_positions/new(.:format)      clients/org_positions#new
# edit_client_org_position GET    /client/:client_id/org_positions/:id/edit(.:format) clients/org_positions#edit
#      client_org_position GET    /client/:client_id/org_positions/:id(.:format)      clients/org_positions#show
#                          PATCH  /client/:client_id/org_positions/:id(.:format)      clients/org_positions#update
#                          PUT    /client/:client_id/org_positions/:id(.:format)      clients/org_positions#update
#                          DELETE /client/:client_id/org_positions/:id(.:format)      clients/org_positions#destroy

describe "routing to Clients Controller" do
  it "routes /client/1/org_positions to clients/org_positions#index" do
    expect(get: "/client/1/org_positions").to route_to(
      controller: "clients/org_positions",
      action: "index",
      client_id: "1"
    )
  end

  it "routes /client/:client_id/org_positions to clients/org_positions#create" do
    expect(post: "/client/1/org_positions").to route_to(
      controller: "clients/org_positions",
      action: "create",
      client_id: "1"
    )
  end

  it "routes /client/:client_id/org_positions/new to clients/org_positions#new" do
    expect(get: "/client/1/org_positions/new").to route_to(
      controller: "clients/org_positions",
      action: "new",
      client_id: "1"
    )
  end

  it "routes /client/:client_id/org_positions/:id/edit to clients/org_positions#edit" do
    expect(get: "/client/1/org_positions/2/edit").to route_to(
      controller: "clients/org_positions",
      action: "edit",
      client_id: "1",
      id: "2"
    )
  end

  it "routes /client/:client_id/org_positions/:id to clients/org_positions#show" do
    expect(get: "/client/1/org_positions/2").to route_to(
      controller: "clients/org_positions",
      action: "show",
      client_id: "1",
      id: "2"
    )
  end

  it "routes /client/:client_id/org_positions/:id to clients/org_positions#update" do
    expect(patch: "/client/1/org_positions/2").to route_to(
      controller: "clients/org_positions",
      action: "update",
      client_id: "1",
      id: "2"
    )
  end

  it "routes /client/:client_id/org_positions/:id to clients/org_positions#update" do
    expect(put: "/client/1/org_positions/2").to route_to(
      controller: "clients/org_positions",
      action: "update",
      client_id: "1",
      id: "2"
    )
  end

  it "routes /client/:client_id/org_positions/:id to clients/org_positions#destroy" do
    expect(delete: "/client/1/org_positions/2").to route_to(
      controller: "clients/org_positions",
      action: "destroy",
      client_id: "1",
      id: "2"
    )
  end
end