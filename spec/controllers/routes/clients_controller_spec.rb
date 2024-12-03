# /Users/Kevin/Rails Projects/funyl/spec/controllers/routes/clients_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/routes/clients_controller_spec.rb
require 'rails_helper'
#         client_upgrade GET    /clients/:client_id/upgrade(.:format)                                       clients#upgrade
# client_upgrade_account POST   /clients/:client_id/upgrade(.:format)                                       clients#upgrade_account
#                clients POST   /clients(.:format)                                                          clients#create
#             new_client GET    /clients/new(.:format)                                                      clients#new
#            edit_client GET    /clients/:client_id/edit(.:format)                                          clients#edit
#                        PATCH  /clients/:client_id(.:format)                                               clients#update
#                        PUT    /clients/:client_id(.:format)                                               clients#update
#                        DELETE /clients/:client_id(.:format)                                               clients#destroy
#     client_file_upload POST   /clients/:client_id/file_upload(.:format)                                   clients#file_upload
#   client_update_agency PATCH  /clients/:client_id/update_agency(.:format)                                 clients#update_agency
#      client_users_list GET    /clients/:client_id/user_list(.:format)                                     clients#user_list {:format=>:json}

describe "routing to Clients Controller", :special do
  it "routes /clients/:client_id/upgrade to clients#upgrade" do
    expect(get: "/clients/1/upgrade").to route_to(
      controller: "clients",
      action: "upgrade",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id/upgrade to clients#upgrade_account" do
    expect(post: "/clients/1/upgrade").to route_to(
      controller: "clients",
      action: "upgrade_account",
      client_id: "1"
    )
  end

  it "routes /clients to clients#create" do
    expect(post: "/clients").to route_to(
      controller: "clients",
      action: "create"
    )
  end

  it "routes /clients/new to clients#new" do
    expect(get: "/clients/new").to route_to(
      controller: "clients",
      action: "new"
    )
  end

  it "routes /clients/:client_id/edit to clients#edit" do
    expect(get: "/clients/1/edit").to route_to(
      controller: "clients",
      action: "edit",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id to clients#update" do
    expect(patch: "/clients/1").to route_to(
      controller: "clients",
      action: "update",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id to clients#update" do
    expect(put: "/clients/1").to route_to(
      controller: "clients",
      action: "update",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id to clients#destroy" do
    expect(delete: "/clients/1").to route_to(
      controller: "clients",
      action: "destroy",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id/file_upload to clients#file_upload" do
    expect(post: "/clients/1/file_upload").to route_to(
      controller: "clients",
      action: "file_upload",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id/update_agency to clients#update_agency" do
    expect(patch: "/clients/1/update_agency").to route_to(
      controller: "clients",
      action: "update_agency",
      client_id: "1"
    )
  end

  it "routes /clients/:client_id/user_list to clients#user_list" do
    expect(get: "/clients/1/user_list").to route_to(
    	format: :json,
      controller: "clients",
      action: "user_list",
      client_id: "1"
    )
  end

  it "routes /client to clients#validate_unique_email" do
    expect(get: "/validate_unique_email").to route_to(
      format: :json,
      controller: "clients",
      action: "validate_unique_email"
    )
  end
end
