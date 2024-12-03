# /Users/Kevin/Rails Projects/funyl/spec/controllers/welcome_controller_spec.rb
# foreman run bundle exec rspec spec/controllers/welcome_controller_spec.rb
require 'rails_helper'

#           welcome_about GET  /welcome/about(.:format)                              redirect(301, https://www.chiirp.com)
#         welcome_contact GET  /welcome/contact(.:format)                            redirect(301, https://www.chiirp.com/demo/)
#                         POST /welcome/contact(.:format)                            redirect(301, https://www.chiirp.com/demo/)
#         welcome_courses GET  /welcome/courses(.:format)                            redirect(301, https://www.chiirp.com/watch-demo/)
#            welcome_demo GET  /welcome/demo(.:format)                               redirect(301, https://www.chiirp.com/demo/)
#      welcome_experience GET  /welcome/experience(.:format)                         redirect(301, https://www.chiirp.com/watch-demo/)
#     welcome_failed_link GET  /welcome/failed_link(.:format)                        welcome#failed_link
#        welcome_features GET  /welcome/features(.:format)                           redirect(301, https://www.chiirp.com/features/)
#           welcome_index GET  /welcome/index(.:format)                              redirect(301, https://www.chiirp.com)
#            welcome_join GET  /welcome/join/:package_key(.:format)                  welcome#join
#        welcome_join_min GET  /welcome/join/min/:package_key(.:format)              welcome#join_min
#         welcome_pricing GET  /welcome/pricing/:package_page_key(.:format)          welcome#pricing
#    welcome_pricing_init GET  /welcome/pricing/init/:package_page_key(.:format)     welcome#pricing_init
# welcome_pricing_default GET  /welcome/pricing(.:format)                            welcome#pricing
#         welcome_privacy GET  /welcome/privacy(.:format)                            redirect(301, https://www.chiirp.com/privacy-policy/)
#       welcome_scheduler GET  /welcome/scheduler(.:format)                          redirect(301, https://www.chiirp.com/demo/)
#    welcome_serviceterms GET  /welcome/serviceterms(.:format)                       redirect(301, https://www.chiirp.com/terms-of-service/)
#         welcome_success GET  /welcome/success/:id(.:format)                        welcome#success
#        welcome_training GET  /welcome/training(.:format)                           welcome#training
#             welcome_why GET  /welcome/why(.:format)                                redirect(301, https://chiirp.com)
#     welcome_unsubscribe GET  /welcome/unsubscribe/:client_id/:contact_id(.:format) welcome#unsubscribe

describe "routing to Welcome Controller" do
  it "redirects /welcome/about to https://www.chiirp.com", type: :request do
    get "https://dev.chiirp.com/welcome/about"
    expect(response).to redirect_to("https://www.chiirp.com")
  end

  it "redirects /welcome/contact to https://www.chiirp.com/demo/", type: :request do
    get "https://dev.chiirp.com/welcome/contact"
    expect(response).to redirect_to("https://www.chiirp.com/demo/")
  end

  it "redirects /welcome/contact to https://www.chiirp.com/demo/", type: :request do
    post "https://dev.chiirp.com/welcome/contact"
    expect(response).to redirect_to("https://www.chiirp.com/demo/")
  end

  it "redirects /welcome/courses to https://www.chiirp.com/watch-demo/", type: :request do
    get "https://dev.chiirp.com/welcome/courses"
    expect(response).to redirect_to("https://www.chiirp.com/watch-demo/")
  end

  it "redirects /welcome/demo to https://www.chiirp.com/demo/", type: :request do
    get "https://dev.chiirp.com/welcome/demo"
    expect(response).to redirect_to("https://www.chiirp.com/demo/")
  end

  it "redirects /welcome/experience to https://www.chiirp.com/watch-demo/", type: :request do
    get "https://dev.chiirp.com/welcome/experience"
    expect(response).to redirect_to("https://www.chiirp.com/watch-demo/")
  end

  it "routes /welcome/failed_link to welcome#failed_link" do
    expect(get: "/welcome/failed_link").to route_to(
      controller: "welcome",
      action: "failed_link"
    )
  end

  it "redirects /welcome/features to https://www.chiirp.com/features/", type: :request do
    get "https://dev.chiirp.com/welcome/features"
    expect(response).to redirect_to("https://www.chiirp.com/features/")
  end

  it "redirects /welcome/index to https://www.chiirp.com", type: :request do
    get "https://dev.chiirp.com/welcome/index"
    expect(response).to redirect_to("https://www.chiirp.com")
  end

  it "routes /welcome/join/:package_key to welcome#join" do
    expect(get: "/welcome/join/asdf").to route_to(
      controller: "welcome",
      action: "join",
      package_key: 'asdf'
    )
  end

  it "routes /welcome/join/min/:package_key to welcome#join_min" do
    expect(get: "/welcome/join/min/asdf").to route_to(
      controller: "welcome",
      action: "join_min",
      package_key: 'asdf'
    )
  end

  it "routes /welcome/pricing/:package_page_key to welcome#pricing" do
    expect(get: "/welcome/pricing/asdf").to route_to(
      controller: "welcome",
      action: "pricing",
      package_page_key: 'asdf'
    )
  end

  it "routes /welcome/pricing/init/:package_page_key to welcome#pricing_init" do
    expect(get: "/welcome/pricing/init/asdf").to route_to(
      controller: "welcome",
      action: "pricing_init",
      package_page_key: 'asdf'
    )
  end

  it "routes /welcome/pricing to welcome#pricing" do
    expect(get: "/welcome/pricing").to route_to(
      controller: "welcome",
      action: "pricing"
    )
  end

  it "redirects /welcome/privacy to https://www.chiirp.com/privacy-policy/", type: :request do
    get "https://dev.chiirp.com/welcome/privacy"
    expect(response).to redirect_to("https://www.chiirp.com/privacy-policy/")
  end

  it "redirects /welcome/scheduler to https://www.chiirp.com/demo/", type: :request do
    get "https://dev.chiirp.com/welcome/scheduler"
    expect(response).to redirect_to("https://www.chiirp.com/demo/")
  end

  it "redirects /welcome/serviceterms to https://www.chiirp.com/terms-of-service/", type: :request do
    get "https://dev.chiirp.com/welcome/serviceterms"
    expect(response).to redirect_to("https://www.chiirp.com/terms-of-service/")
  end

  it "routes /welcome/success/:id to welcome#success" do
    expect(get: "/welcome/success/1").to route_to(
      controller: "welcome",
      action: "success",
      id: '1'
    )
  end

  it "routes /welcome/training to welcome#training" do
    expect(get: "/welcome/training").to route_to(
      controller: "welcome",
      action: "training"
    )
  end

  it "redirects /welcome/why to https://www.chiirp.com", type: :request do
    get "https://dev.chiirp.com/welcome/why"
    expect(response).to redirect_to("https://chiirp.com")
  end

  it "routes /welcome/unsubscribe/:client_id/:contact_id to welcome#unsubscribe" do
    expect(get: "/welcome/unsubscribe/1/2").to route_to(
      controller: "welcome",
      action: "unsubscribe",
      client_id: '1',
      contact_id: '2'
    )
  end
end
