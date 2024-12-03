# /Users/Kevin/Rails Projects/funyl/spec/controllers/package_pages_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/package_pages_controller_spec.rb
require 'rails_helper'

#        package_pages GET    /package_pages(.:format)                          package_pages#index
#                      POST   /package_pages(.:format)                          package_pages#create
#     new_package_page GET    /package_pages/new(.:format)                      package_pages#new
#    edit_package_page GET    /package_pages/:id/edit(.:format)                 package_pages#edit
#         package_page PATCH  /package_pages/:id(.:format)                      package_pages#update
#                      PUT    /package_pages/:id(.:format)                      package_pages#update
#                      DELETE /package_pages/:id(.:format)                      package_pages#destroy
#         packagepages GET    /packagepages(.:format)                           package_pages#show
# package_pages_select GET    /package_pages/select(.:format)                   package_pages#select

describe "routing to Package Pages Controller" do
  it "routes /package_pages to packasge_pages#index" do
    expect(get: "/package_pages").to route_to(
      controller: "package_pages",
      action: "index"
    )
  end

  it "routes /package_pages to packasge_pages#create" do
    expect(post: "/package_pages").to route_to(
      controller: "package_pages",
      action: "create"
    )
  end

  it "routes /package_pages/new to packasge_pages#new" do
    expect(get: "/package_pages/new").to route_to(
      controller: "package_pages",
      action: "new"
    )
  end

  it "routes /package_pages/:id/edit to packasge_pages#edit" do
    expect(get: "/package_pages/1/edit").to route_to(
      controller: "package_pages",
      action: "edit",
      id: '1'
    )
  end

  it "routes /package_pages/:id to packasge_pages#update" do
    expect(patch: "/package_pages/1").to route_to(
      controller: "package_pages",
      action: "update",
      id: '1'
    )
  end

  it "routes /package_pages/:id to packasge_pages#update" do
    expect(put: "/package_pages/1").to route_to(
      controller: "package_pages",
      action: "update",
      id: '1'
    )
  end

  it "routes /package_pages/:id to packasge_pages#destroy" do
    expect(delete: "/package_pages/1").to route_to(
      controller: "package_pages",
      action: "destroy",
      id: '1'
    )
  end

  it "routes /packagepages to packasge_pages#show" do
    expect(get: "/packagepages").to route_to(
      controller: "package_pages",
      action: "show"
    )
  end

  it "routes /package_pages/select to packasge_pages#select" do
    expect(get: "/package_pages/select").to route_to(
      controller: "package_pages",
      action: "select"
    )
  end
end
