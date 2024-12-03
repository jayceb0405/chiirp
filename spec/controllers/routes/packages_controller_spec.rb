# /Users/Kevin/Rails Projects/funyl/spec/controllers/packages_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/packages_controller_spec.rb
require 'rails_helper'

#             packages GET    /packages(.:format)                               packages#index
#                      POST   /packages(.:format)                               packages#create
#          new_package GET    /packages/new(.:format)                           packages#new
#         edit_package GET    /packages/:id/edit(.:format)                      packages#edit
#              package PATCH  /packages/:id(.:format)                           packages#update
#                      PUT    /packages/:id(.:format)                           packages#update
#                      DELETE /packages/:id(.:format)                           packages#destroy
#       packagemanager GET    /packagemanager(.:format)                         packages#show
#        image_package PATCH  /packages/:id/image(.:format)                     packages#image

describe "routing to Packages Controller" do
  it "routes /packages to packages#index" do
    expect(get: "/packages").to route_to(
      controller: "packages",
      action: "index"
    )
  end

  it "routes /packages to packages#create" do
    expect(post: "/packages").to route_to(
      controller: "packages",
      action: "create"
    )
  end

  it "routes /packages/new to packages#new" do
    expect(get: "/packages/new").to route_to(
      controller: "packages",
      action: "new"
    )
  end

  it "routes /packages/:id/edit to packages#edit" do
    expect(get: "/packages/1/edit").to route_to(
      controller: "packages",
      action: "edit",
      id: '1'
    )
  end

  it "routes /packages/:id to packages#update" do
    expect(patch: "/packages/1").to route_to(
      controller: "packages",
      action: "update",
      id: '1'
    )
  end

  it "routes /packages/:id to packages#update" do
    expect(put: "/packages/1").to route_to(
      controller: "packages",
      action: "update",
      id: '1'
    )
  end

  it "routes /packages/:id to packages#destroy" do
    expect(delete: "/packages/1").to route_to(
      controller: "packages",
      action: "destroy",
      id: '1'
    )
  end

  it "routes /packagemanager to packages#show" do
    expect(get: "/packagemanager").to route_to(
      controller: "packages",
      action: "show"
    )
  end

  it "routes /packages/:id/image to packages#image" do
    expect(patch: "/packages/1/image").to route_to(
      controller: "packages",
      action: "image",
      id: '1'
    )
  end
end
