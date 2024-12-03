# /Users/Kevin/Rails Projects/funyl/spec/controllers/user_contact_forms_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/user_contact_forms_controller_spec.rb
require 'rails_helper'
#                                           GET    /:page_key(.:format)                                      api/v3/user_contact_forms#show_page
#                                           POST   /:page_key(.:format)                                      api/v3/user_contact_forms#save_contact
#                        user_contact_forms GET    /user_contact_forms(.:format)                             user_contact_forms#index
#                         user_contact_form DELETE /user_contact_forms/:id(.:format)                         user_contact_forms#destroy
#            index_import_user_contact_form GET    /user_contact_form/import/index(.:format)                 user_contact_forms#index_import
#                  import_user_contact_form POST   /user_contact_form/import(.:format)                       user_contact_forms#import
#             edit_api_v2_user_contact_form GET    /api/v2/user_contact_forms/:id/edit(.:format)             api/v2/user_contact_forms#edit
#                  api_v2_user_contact_form PATCH  /api/v2/user_contact_forms/:id(.:format)                  api/v2/user_contact_forms#update
#                                           PUT    /api/v2/user_contact_forms/:id(.:format)                  api/v2/user_contact_forms#update
#             api_v2_user_contact_form_link GET    /api/v2/quicklead/link/:page_key(.:format)                api/v2/user_contact_forms#show_link
#       api_v2_user_contact_form_modal_init GET    /api/v2/quicklead/modalinit/:page_key(.:format)           api/v2/user_contact_forms#show_modal_init
#            api_v2_user_contact_form_modal GET    /api/v2/quicklead/modal/:page_key(.:format)               api/v2/user_contact_forms#show_modal
#       api_v2_user_contact_form_frame_init GET    /api/v2/quicklead/frameinit/:page_key(.:format)           api/v2/user_contact_forms#show_frame_init
#            api_v2_user_contact_form_frame GET    /api/v2/quicklead/frame/:page_key(.:format)               api/v2/user_contact_forms#show_frame
#             api_v2_user_contact_form_form GET    /api/v2/quicklead/form/:page_key(.:format)                api/v2/user_contact_forms#show_form
#             api_v2_user_contact_form_page GET    /api/v2/quicklead/:page_key(.:format)                     api/v2/user_contact_forms#show_page
#     api_v2_user_contact_form_save_contact POST   /api/v2/quicklead/:page_key(.:format)                     api/v2/user_contact_forms#save_contact
#                 api_v3_user_contact_forms POST   /api/v3/user_contact_forms(.:format)                      api/v3/user_contact_forms#create
#              new_api_v3_user_contact_form GET    /api/v3/user_contact_forms/new(.:format)                  api/v3/user_contact_forms#new
#             edit_api_v3_user_contact_form GET    /api/v3/user_contact_forms/:id/edit(.:format)             api/v3/user_contact_forms#edit
#                  api_v3_user_contact_form PATCH  /api/v3/user_contact_forms/:id(.:format)                  api/v3/user_contact_forms#update
#                                           PUT    /api/v3/user_contact_forms/:id(.:format)                  api/v3/user_contact_forms#update
#                         api_v3_quickleads GET    /api/v3/quickleads(.:format)                              api/v3/user_contact_forms#show
# api_v3_background_image_user_contact_form PATCH  /api/v3/users/contact_form/:id/background_image(.:format) api/v3/user_contact_forms#background_image
#             api_v3_show_user_contact_form GET    /api/v3/users/contact_form/:page_key(.:format)            api/v3/user_contact_forms#show_contact_form
#                       api_v3_save_contact POST   /api/v3/users/contact_form/:page_key(.:format)            api/v3/user_contact_forms#save_contact
#       api_v3_user_contact_form_modal_init GET    /api/v3/quicklead/modalinit/:page_key(.:format)           api/v3/user_contact_forms#show_modal_init
#            api_v3_user_contact_form_modal GET    /api/v3/quicklead/modal/:page_key(.:format)               api/v3/user_contact_forms#show_modal
#       api_v3_user_contact_form_frame_init GET    /api/v3/quicklead/frameinit/:page_key(.:format)           api/v3/user_contact_forms#show_frame_init
#            api_v3_user_contact_form_frame GET    /api/v3/quicklead/frame/:page_key(.:format)               api/v3/user_contact_forms#show_frame
#             api_v3_user_contact_form_page GET    /api/v3/quicklead/:page_key(.:format)                     api/v3/user_contact_forms#show_page
#     api_v3_user_contact_form_save_contact POST   /api/v3/quicklead/:page_key(.:format)                     api/v3/user_contact_forms#save_contact

describe "routing to UserContactForms" do
  it "routes /user_contact_forms to user_contact_forms#index" do
    expect(get: "user_contact_forms").to route_to(
      controller: "user_contact_forms",
      action: "index"
    )
  end

  it "routes /user_contact_forms/:id to user_contact_forms#destroy" do
    expect(delete: "user_contact_forms/1").to route_to(
      controller: "user_contact_forms",
      action: "destroy",
      id: "1"
    )
  end

  it "routes /user_contact_form/import/index to user_contact_forms#index_import" do
    allow_any_instance_of(ActionDispatch::Request).to receive(:xhr?).and_return(true)
    expect(get: "user_contact_form/import/index").to route_to(
      controller: "user_contact_forms",
      action: "index_import"
    )
  end

  it "routes /user_contact_form/import to user_contact_forms#import" do
    expect(post: "user_contact_form/import").to route_to(
      controller: "user_contact_forms",
      action: "import"
    )
  end

  it "routes /api/v2/user_contact_forms/:id/edit to api/v2/user_contact_forms#edit" do
    expect(get: "api/v2/user_contact_forms/M01yjsxdgprFaI4FpEnB/edit").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "edit",
      id: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/user_contact_forms/:id to api/v2/user_contact_forms#update" do
    expect(patch: "api/v2/user_contact_forms/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "update",
      id: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/user_contact_forms/:id to api/v2/user_contact_forms#update" do
    expect(put: "api/v2/user_contact_forms/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "update",
      id: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/link/:page_key to api/v2/user_contact_forms#show_link" do
    expect(get: "api/v2/quicklead/link/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_link",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/modalinit/:page_key to api/v2/user_contact_forms#show_modal_init" do
    expect(get: "api/v2/quicklead/modalinit/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_modal_init",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/modal/:page_key to api/v2/user_contact_forms#show_modal" do
    expect(get: "api/v2/quicklead/modal/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_modal",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/frameinit/:page_key to api/v2/user_contact_forms#show_frame_init" do
    expect(get: "api/v2/quicklead/frameinit/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_frame_init",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/frame/:page_key to api/v2/user_contact_forms#show_frame" do
    expect(get: "api/v2/quicklead/frame/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_frame",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/form/:page_key to api/v2/user_contact_forms#show_form" do
    expect(get: "api/v2/quicklead/form/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_form",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/:page_key to api/v2/user_contact_forms#show_page" do
    expect(get: "api/v2/quicklead/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "show_page",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v2/quicklead/:page_key to api/v2/user_contact_forms#save_contact" do
    expect(post: "api/v2/quicklead/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v2/user_contact_forms",
      action: "save_contact",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/user_contact_forms to api/v3/user_contact_forms#create" do
    expect(post: "api/v3/user_contact_forms").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "create"
    )
  end

  it "routes /api/v3/user_contact_forms/new to api/v3/user_contact_forms#new" do
    expect(get: "api/v3/user_contact_forms/new").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "new"
    )
  end

  it "routes /api/v3/user_contact_forms/:id/edit to api/v3/user_contact_forms#edit" do
    expect(get: "api/v3/user_contact_forms/1/edit").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "edit",
      id: "1"
    )
  end

  it "routes /api/v3/user_contact_forms/:id to api/v3/user_contact_forms#update" do
    expect(patch: "api/v3/user_contact_forms/1").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "update",
      id: "1"
    )
  end

  it "routes /api/v3/user_contact_forms/:id to api/v3/user_contact_forms#update" do
    expect(put: "api/v3/user_contact_forms/1").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "update",
      id: "1"
    )
  end

  it "routes /api/v3/quickleads to api/v3/user_contact_forms#show" do
    expect(get: "api/v3/quickleads").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show"
    )
  end

  it "routes /api/v3/users/contact_form/:id/background_image to api/v3/user_contact_forms#background_image" do
    expect(patch: "api/v3/users/contact_form/1/background_image").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "background_image",
      id: "1"
    )
  end

  it "routes /api/v3/users/contact_form/:page_key to api/v3/user_contact_forms#show_contact_form" do
    expect(get: "api/v3/users/contact_form/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_contact_form",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/users/contact_form/:page_key to api/v3/user_contact_forms#save_contact" do
    expect(post: "api/v3/users/contact_form/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "save_contact",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/quicklead/modalinit/:page_key to api/v3/user_contact_forms#show_modal_init" do
    expect(get: "api/v3/quicklead/modalinit/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_modal_init",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/quicklead/modal/:page_key to api/v3/user_contact_forms#show_modal" do
    expect(get: "api/v3/quicklead/modal/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_modal",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/quicklead/frameinit/:page_key to api/v3/user_contact_forms#show_frame_init" do
    expect(get: "api/v3/quicklead/frameinit/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_frame_init",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/quicklead/frame/:page_key to api/v3/user_contact_forms#show_frame" do
    expect(get: "api/v3/quicklead/frame/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_frame",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/quicklead/:page_key to api/v3/user_contact_forms#show_page" do
    expect(get: "api/v3/quicklead/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_page",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /api/v3/quicklead/:page_key to api/v3/user_contact_forms#save_contact" do
    expect(post: "api/v3/quicklead/M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "save_contact",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /:page_key to api/v3/user_contact_forms#show_page" do
    allow_any_instance_of(Constraints::QuickPage).to receive(:matches?).and_return(true)
    expect(get: "M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "show_page",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end

  it "routes /:page_key to api/v3/user_contact_forms#save_contact" do
    allow_any_instance_of(Constraints::QuickPage).to receive(:matches?).and_return(true)
    expect(post: "M01yjsxdgprFaI4FpEnB").to route_to(
      controller: "api/v3/user_contact_forms",
      action: "save_contact",
      page_key: "M01yjsxdgprFaI4FpEnB"
    )
  end
end
