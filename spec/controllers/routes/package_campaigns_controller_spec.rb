# /Users/Kevin/Rails Projects/funyl/spec/controllers/package_campaigns_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/package_campaigns_controller_spec.rb
require 'rails_helper'

#    package_campaigns GET    /packages/:package_id/campaigns(.:format)         package_campaigns#index
#                      POST   /packages/:package_id/campaigns(.:format)         package_campaigns#create
# new_package_campaign GET    /packages/:package_id/campaigns/new(.:format)     package_campaigns#new
#     package_campaign DELETE /packages/:package_id/campaigns/:id(.:format)     package_campaigns#destroy

describe "routing to Package Campaigns Controller" do
  it "routes /packages/:package_id/campaigns to package_campaigns#index" do
    expect(get: "/packages/1/campaigns").to route_to(
      controller: "package_campaigns",
      action: "index",
      package_id: '1'
    )
  end

  it "routes /packages/:package_id/campaigns to package_campaigns#create" do
    expect(post: "/packages/1/campaigns").to route_to(
      controller: "package_campaigns",
      action: "create",
      package_id: '1'
    )
  end

  it "routes /packages/:package_id/campaigns to package_campaigns#new" do
    expect(get: "/packages/1/campaigns/new").to route_to(
      controller: "package_campaigns",
      action: "new",
      package_id: '1'
    )
  end

  it "routes /packages/:package_id/campaigns/:id to package_campaigns#destroy" do
    expect(delete: "/packages/1/campaigns/2").to route_to(
      controller: "package_campaigns",
      action: "destroy",
      package_id: '1',
      id: '2'
    )
  end
end
