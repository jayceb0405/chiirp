# /Users/Kevin/Rails Projects/funyl/spec/controllers/user_contact_form_marketplaces_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/user_contact_form_marketplaces_controller_spec.rb
require 'rails_helper'
#            approve_user_contact_form POST  /user_contact_form_marketplaces/:id/approve(.:format) user_contact_form_marketplaces#approve
#                buy_user_contact_form POST  /user_contact_form_marketplaces/:id/buy(.:format)     user_contact_form_marketplaces#buy
# image_user_contact_form_marketplaces PATCH /user_contact_form_marketplaces/:id/image(.:format)   user_contact_form_marketplaces#image
#       user_contact_form_marketplaces GET   /user_contact_form_marketplaces(.:format)             user_contact_form_marketplaces#index
#   edit_user_contact_form_marketplace GET   /user_contact_form_marketplaces/:id/edit(.:format)    user_contact_form_marketplaces#edit
#        user_contact_form_marketplace GET   /user_contact_form_marketplaces/:id(.:format)         user_contact_form_marketplaces#show
#                                      PATCH /user_contact_form_marketplaces/:id(.:format)         user_contact_form_marketplaces#update
#                                      PUT   /user_contact_form_marketplaces/:id(.:format)         user_contact_form_marketplaces#update

describe "routing to UserContactFormMarketplaces" do
  it "routes /user_contact_form_marketplaces/:id/approve to user_contact_form_marketplaces#approve" do
    expect(post: "/user_contact_form_marketplaces/1/approve").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "approve",
      id: "1"
    )
  end

  it "routes /user_contact_form_marketplaces/:id/buy to user_contact_form_marketplaces#buy" do
    expect(post: "/user_contact_form_marketplaces/1/buy").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "buy",
      id: "1"
    )
  end

  it "routes /user_contact_form_marketplaces/:id/image to user_contact_form_marketplaces#image" do
    expect(patch: "/user_contact_form_marketplaces/1/image").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "image",
      id: "1"
    )
  end

  it "routes /user_contact_form_marketplaces to user_contact_form_marketplaces#index" do
    expect(get: "/user_contact_form_marketplaces").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "index"
    )
  end

  it "routes /user_contact_form_marketplaces/:id/edit to user_contact_form_marketplaces#edit" do
    expect(get: "/user_contact_form_marketplaces/1/edit").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "edit",
      id: "1"
    )
  end

  it "routes /user_contact_form_marketplaces/:id to user_contact_form_marketplaces#show" do
    expect(get: "/user_contact_form_marketplaces/1").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "show",
      id: "1"
    )
  end

  it "routes /user_contact_form_marketplaces/:id to user_contact_form_marketplaces#update" do
    expect(patch: "/user_contact_form_marketplaces/1").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "update",
      id: "1"
    )
  end

  it "routes /user_contact_form_marketplaces/:id to user_contact_form_marketplaces#update" do
    expect(put: "/user_contact_form_marketplaces/1").to route_to(
      controller: "user_contact_form_marketplaces",
      action: "update",
      id: "1"
    )
  end
end
