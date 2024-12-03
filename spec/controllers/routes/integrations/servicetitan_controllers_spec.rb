# /Users/Kevin/Rails Projects/funyl/spec/controllers/integrations/servicetitan_controllers_spec.rb
# foreman run bundle exec rspec spec/controllers/routes/integrations/servicetitan_controllers_spec.rb
require 'rails_helper'
#                          integrations_servicetitan GET    /integrations/servicetitan(.:format)                                   integrations/servicetitan/integrations#show
#        integrations_servicetitan_contacts_balances GET    /integrations/servicetitan/contacts/balances(.:format)                 integrations/servicetitan/contacts#index_balances
#     integrations_servicetitan_contacts_import_jobs POST   /integrations/servicetitan/contacts/import_jobs/:contact_id(.:format)  integrations/servicetitan/contacts#import_jobs
#        integrations_servicetitan_contacts_invoices GET    /integrations/servicetitan/contacts/invoices/:contact_id(.:format)     integrations/servicetitan/contacts#index_invoices
#                 integrations_servicetitan_endpoint POST   /integrations/servicetitan/endpoint/:webhook/:api_key(.:format)        integrations/servicetitan/integrations#endpoint
#                 integrations_servicetitan_endpoint POST   /integrations/servicetitan/endpoint(.:format)                          integrations/servicetitan/integrations#endpoint
#                  integrations_servicetitan_api_key GET    /integrations/servicetitan/api_key(.:format)                           integrations/servicetitan/api_keys#show
#                                                    PATCH  /integrations/servicetitan/api_key(.:format)                           integrations/servicetitan/api_keys#update
#                                                    PUT    /integrations/servicetitan/api_key(.:format)                           integrations/servicetitan/api_keys#update
#           integrations_servicetitan_balance_update GET    /integrations/servicetitan/balance_update(.:format)                    integrations/servicetitan/balance_updates#show
#                                                    PATCH  /integrations/servicetitan/balance_update(.:format)                    integrations/servicetitan/balance_updates#update
#                                                    PUT    /integrations/servicetitan/balance_update(.:format)                    integrations/servicetitan/balance_updates#update
#           integrations_servicetitan_business_units GET    /integrations/servicetitan/business_units(.:format)                    integrations/servicetitan/business_units#show
#                                                    PATCH  /integrations/servicetitan/business_units(.:format)                    integrations/servicetitan/business_units#update
#                                                    PUT    /integrations/servicetitan/business_units(.:format)                    integrations/servicetitan/business_units#update
#     edit_integrations_servicetitan_contact_booking GET    /integrations/servicetitan/contact_bookings/:contact_id/edit(.:format) integrations/servicetitan/contact_bookings#edit
#          integrations_servicetitan_contact_booking PATCH  /integrations/servicetitan/contact_bookings/:contact_id(.:format)      integrations/servicetitan/contact_bookings#update
#                                                    PUT    /integrations/servicetitan/contact_bookings/:contact_id(.:format)      integrations/servicetitan/contact_bookings#update
#             edit_integrations_servicetitan_contact GET    /integrations/servicetitan/contacts/:contact_id/edit(.:format)         integrations/servicetitan/contacts#edit
#                  integrations_servicetitan_contact PATCH  /integrations/servicetitan/contacts/:contact_id(.:format)              integrations/servicetitan/contacts#update
#                                                    PUT    /integrations/servicetitan/contacts/:contact_id(.:format)              integrations/servicetitan/contacts#update
#       edit_integrations_servicetitan_custom_fields GET    /integrations/servicetitan/custom_fields/edit(.:format)                integrations/servicetitan/custom_fields#edit
#            integrations_servicetitan_custom_fields PATCH  /integrations/servicetitan/custom_fields(.:format)                     integrations/servicetitan/custom_fields#update
#                                                    PUT    /integrations/servicetitan/custom_fields(.:format)                     integrations/servicetitan/custom_fields#update
#                                                    GET    /integrations/servicetitan/custom_fields(.:format)                     integrations/servicetitan/custom_fields#index
#                integrations_servicetitan_employees GET    /integrations/servicetitan/employees(.:format)                         integrations/servicetitan/employees#show
#                                                    PATCH  /integrations/servicetitan/employees(.:format)                         integrations/servicetitan/employees#update
#                                                    PUT    /integrations/servicetitan/employees(.:format)                         integrations/servicetitan/employees#update
#               new_integrations_servicetitan_events GET    /integrations/servicetitan/events/new(.:format)                        integrations/servicetitan/events#new
#              edit_integrations_servicetitan_events GET    /integrations/servicetitan/events/edit(.:format)                       integrations/servicetitan/events#edit
#                   integrations_servicetitan_events GET    /integrations/servicetitan/events(.:format)                            integrations/servicetitan/events#show
#                                                    PATCH  /integrations/servicetitan/events(.:format)                            integrations/servicetitan/events#update
#                                                    PUT    /integrations/servicetitan/events(.:format)                            integrations/servicetitan/events#update
#                                                    DELETE /integrations/servicetitan/events(.:format)                            integrations/servicetitan/events#destroy
#                   integrations_servicetitan_import GET    /integrations/servicetitan/import(.:format)                            integrations/servicetitan/imports#show
#                                                    PATCH  /integrations/servicetitan/import(.:format)                            integrations/servicetitan/imports#update
#                                                    PUT    /integrations/servicetitan/import(.:format)                            integrations/servicetitan/imports#update
#             integrations_servicetitan_instructions GET    /integrations/servicetitan/instructions(.:format)                      integrations/servicetitan/instructions#show
#             integrations_servicetitan_job_arrivals GET    /integrations/servicetitan/job_arrivals(.:format)                      integrations/servicetitan/job_arrivals#show
#                                                    PATCH  /integrations/servicetitan/job_arrivals(.:format)                      integrations/servicetitan/job_arrivals#update
#                                                    PUT    /integrations/servicetitan/job_arrivals(.:format)                      integrations/servicetitan/job_arrivals#update
#      integrations_servicetitan_job_classifications GET    /integrations/servicetitan/job_classifications(.:format)               integrations/servicetitan/job_classifications#show
#                                                    PATCH  /integrations/servicetitan/job_classifications(.:format)               integrations/servicetitan/job_classifications#update
#                                                    PUT    /integrations/servicetitan/job_classifications(.:format)               integrations/servicetitan/job_classifications#update
#    edit_integrations_servicetitan_minimum_job_fees GET    /integrations/servicetitan/minimum_job_fees/edit(.:format)             integrations/servicetitan/minimum_job_fees#edit
#         integrations_servicetitan_minimum_job_fees PATCH  /integrations/servicetitan/minimum_job_fees(.:format)                  integrations/servicetitan/minimum_job_fees#update
#                                                    PUT    /integrations/servicetitan/minimum_job_fees(.:format)                  integrations/servicetitan/minimum_job_fees#update
#                  integrations_servicetitan_regions GET    /integrations/servicetitan/regions(.:format)                           integrations/servicetitan/regions#index
#                                                    POST   /integrations/servicetitan/regions(.:format)                           integrations/servicetitan/regions#create
#              edit_integrations_servicetitan_region GET    /integrations/servicetitan/regions/:region/edit(.:format)              integrations/servicetitan/regions#edit
#                   integrations_servicetitan_region PATCH  /integrations/servicetitan/regions/:region(.:format)                   integrations/servicetitan/regions#update
#                                                    PUT    /integrations/servicetitan/regions/:region(.:format)                   integrations/servicetitan/regions#update
#                                                    DELETE /integrations/servicetitan/regions/:region(.:format)                   integrations/servicetitan/regions#destroy
#                   integrations_servicetitan_trades GET    /integrations/servicetitan/trades(.:format)                            integrations/servicetitan/trades#index
#                                                    POST   /integrations/servicetitan/trades(.:format)                            integrations/servicetitan/trades#create
#               edit_integrations_servicetitan_trade GET    /integrations/servicetitan/trades/:trade/edit(.:format)                integrations/servicetitan/trades#edit
#                    integrations_servicetitan_trade PATCH  /integrations/servicetitan/trades/:trade(.:format)                     integrations/servicetitan/trades#update
#                                                    PUT    /integrations/servicetitan/trades/:trade(.:format)                     integrations/servicetitan/trades#update
#                                                    DELETE /integrations/servicetitan/trades/:trade(.:format)                     integrations/servicetitan/trades#destroy


#                   integrations_servicetitan_import GET    /integrations/servicetitan/import(.:format)                            integrations/servicetitan/imports#show
#                                                    PATCH  /integrations/servicetitan/import(.:format)                            integrations/servicetitan/imports#update
#                                                    PUT    /integrations/servicetitan/import(.:format)                            integrations/servicetitan/imports#update
#              integrations_servicetitan_import_jobs GET    /integrations/servicetitan/import_jobs(.:format)                       integrations/servicetitan/import_jobs#show
#                                                    PATCH  /integrations/servicetitan/import_jobs(.:format)                       integrations/servicetitan/import_jobs#update
#                                                    PUT    /integrations/servicetitan/import_jobs(.:format)                       integrations/servicetitan/import_jobs#update
#             integrations_servicetitan_instructions GET    /integrations/servicetitan/instructions(.:format)                      integrations/servicetitan/instructions#show
#             integrations_servicetitan_job_arrivals GET    /integrations/servicetitan/job_arrivals(.:format)                      integrations/servicetitan/job_arrivals#show
#                                                    PATCH  /integrations/servicetitan/job_arrivals(.:format)                      integrations/servicetitan/job_arrivals#update
#                                                    PUT    /integrations/servicetitan/job_arrivals(.:format)                      integrations/servicetitan/job_arrivals#update
#      integrations_servicetitan_job_classifications GET    /integrations/servicetitan/job_classifications(.:format)               integrations/servicetitan/job_classifications#show
#                                                    PATCH  /integrations/servicetitan/job_classifications(.:format)               integrations/servicetitan/job_classifications#update
#                                                    PUT    /integrations/servicetitan/job_classifications(.:format)               integrations/servicetitan/job_classifications#update
#    edit_integrations_servicetitan_minimum_job_fees GET    /integrations/servicetitan/minimum_job_fees/edit(.:format)             integrations/servicetitan/minimum_job_fees#edit
#         integrations_servicetitan_minimum_job_fees PATCH  /integrations/servicetitan/minimum_job_fees(.:format)                  integrations/servicetitan/minimum_job_fees#update
#                                                    PUT    /integrations/servicetitan/minimum_job_fees(.:format)                  integrations/servicetitan/minimum_job_fees#update
#            integrations_servicetitan_push_contacts GET    /integrations/servicetitan/push_contacts(.:format)                     integrations/servicetitan/push_contacts#index
#         new_integrations_servicetitan_push_contact GET    /integrations/servicetitan/push_contacts/new(.:format)                 integrations/servicetitan/push_contacts#new
#        edit_integrations_servicetitan_push_contact GET    /integrations/servicetitan/push_contacts/:id/edit(.:format)            integrations/servicetitan/push_contacts#edit
#             integrations_servicetitan_push_contact PATCH  /integrations/servicetitan/push_contacts/:id(.:format)                 integrations/servicetitan/push_contacts#update
#                                                    PUT    /integrations/servicetitan/push_contacts/:id(.:format)                 integrations/servicetitan/push_contacts#update
#                                                    DELETE /integrations/servicetitan/push_contacts/:id(.:format)                 integrations/servicetitan/push_contacts#destroy
#                  integrations_servicetitan_regions GET    /integrations/servicetitan/regions(.:format)                           integrations/servicetitan/regions#index
#                                                    POST   /integrations/servicetitan/regions(.:format)                           integrations/servicetitan/regions#create
#              edit_integrations_servicetitan_region GET    /integrations/servicetitan/regions/:region/edit(.:format)              integrations/servicetitan/regions#edit
#                   integrations_servicetitan_region PATCH  /integrations/servicetitan/regions/:region(.:format)                   integrations/servicetitan/regions#update
#                                                    PUT    /integrations/servicetitan/regions/:region(.:format)                   integrations/servicetitan/regions#update
#                                                    DELETE /integrations/servicetitan/regions/:region(.:format)                   integrations/servicetitan/regions#destroy
#                   integrations_servicetitan_trades GET    /integrations/servicetitan/trades(.:format)                            integrations/servicetitan/trades#index
#                                                    POST   /integrations/servicetitan/trades(.:format)                            integrations/servicetitan/trades#create
#               edit_integrations_servicetitan_trade GET    /integrations/servicetitan/trades/:trade/edit(.:format)                integrations/servicetitan/trades#edit
#                    integrations_servicetitan_trade PATCH  /integrations/servicetitan/trades/:trade(.:format)                     integrations/servicetitan/trades#update
#                                                    PUT    /integrations/servicetitan/trades/:trade(.:format)                     integrations/servicetitan/trades#update
#                                                    DELETE /integrations/servicetitan/trades/:trade(.:format)                     integrations/servicetitan/trades#destroy
describe "routing to Integrations > Servicetitan > Integrations Controller", :special do
  it "routes /integrations/servicetitan to integrations/servicetitan/integrations#show" do
    expect(get: "/integrations/servicetitan").to route_to(
      controller: "integrations/servicetitan/integrations",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/contacts/balances to integrations/servicetitan/contacts#index_balances" do
    expect(get: "/integrations/servicetitan/contacts/balances").to route_to(
      controller: "integrations/servicetitan/contacts",
      action: "index_balances"
    )
  end

  it "routes /integrations/servicetitan/contacts/import_jobs/:contact_id to integrations/servicetitan/contacts#import_jobs" do
    expect(post: "/integrations/servicetitan/contacts/import_jobs/1").to route_to(
      controller: "integrations/servicetitan/contacts",
      action: "import_jobs",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/contacts/invoices/:contact_id to integrations/servicetitan/contacts#index_invoices" do
    expect(get: "/integrations/servicetitan/contacts/invoices/1").to route_to(
      controller: "integrations/servicetitan/contacts",
      action: "index_invoices",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/endpoint/:webhook/:api_key to integrations/servicetitan/integrations#endpoint" do
    expect(post: "/integrations/servicetitan/endpoint/asdf/1234").to route_to(
      controller: "integrations/servicetitan/integrations",
      action: "endpoint",
      webhook: "asdf",
      api_key: "1234"
    )
  end

  it "routes /integrations/servicetitan/endpoint to integrations/servicetitan/integrations#endpoint" do
    expect(post: "/integrations/servicetitan/endpoint").to route_to(
      controller: "integrations/servicetitan/integrations",
      action: "endpoint"
    )
  end

  it "routes /integrations/servicetitan/api_key to integrations/servicetitan/api_keys#show" do
    expect(get: "/integrations/servicetitan/api_key").to route_to(
      controller: "integrations/servicetitan/api_keys",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/api_key to integrations/servicetitan/api_keys#update" do
    expect(patch: "/integrations/servicetitan/api_key").to route_to(
      controller: "integrations/servicetitan/api_keys",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/api_key to integrations/servicetitan/api_keys#update" do
    expect(put: "/integrations/servicetitan/api_key").to route_to(
      controller: "integrations/servicetitan/api_keys",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/balance_update to integrations/servicetitan/balance_updates#show" do
    expect(get: "/integrations/servicetitan/balance_update").to route_to(
      controller: "integrations/servicetitan/balance_updates",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/balance_update to integrations/servicetitan/balance_updates#update" do
    expect(patch: "/integrations/servicetitan/balance_update").to route_to(
      controller: "integrations/servicetitan/balance_updates",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/balance_update to integrations/servicetitan/balance_updates#update" do
    expect(put: "/integrations/servicetitan/balance_update").to route_to(
      controller: "integrations/servicetitan/balance_updates",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/business_units to integrations/servicetitan/business_units#show" do
    expect(get: "/integrations/servicetitan/business_units").to route_to(
      controller: "integrations/servicetitan/business_units",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/business_units to integrations/servicetitan/business_units#update" do
    expect(patch: "/integrations/servicetitan/business_units").to route_to(
      controller: "integrations/servicetitan/business_units",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/business_units to integrations/servicetitan/business_units#update" do
    expect(put: "/integrations/servicetitan/business_units").to route_to(
      controller: "integrations/servicetitan/business_units",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/contact_bookings/:contact_id/edit to integrations/servicetitan/contact_bookings#edit" do
    expect(get: "/integrations/servicetitan/contact_bookings/1/edit").to route_to(
      controller: "integrations/servicetitan/contact_bookings",
      action: "edit",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/contact_bookings/:contact_id to integrations/servicetitan/contact_bookings#update" do
    expect(patch: "/integrations/servicetitan/contact_bookings/1").to route_to(
      controller: "integrations/servicetitan/contact_bookings",
      action: "update",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/contact_bookings/:contact_id to integrations/servicetitan/contact_bookings#update" do
    expect(put: "/integrations/servicetitan/contact_bookings/1").to route_to(
      controller: "integrations/servicetitan/contact_bookings",
      action: "update",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/contacts/:contact_id/edit to integrations/servicetitan/contacts#edit" do
    expect(get: "/integrations/servicetitan/contacts/1/edit").to route_to(
      controller: "integrations/servicetitan/contacts",
      action: "edit",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/contacts/:contact_id to integrations/servicetitan/contacts#update" do
    expect(patch: "/integrations/servicetitan/contacts/1").to route_to(
      controller: "integrations/servicetitan/contacts",
      action: "update",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/contacts/:contact_id to integrations/servicetitan/contacts#update" do
    expect(put: "/integrations/servicetitan/contacts/1").to route_to(
      controller: "integrations/servicetitan/contacts",
      action: "update",
      contact_id: "1"
    )
  end

  it "routes /integrations/servicetitan/custom_fields/edit to integrations/servicetitan/custom_fields#edit" do
    expect(get: "/integrations/servicetitan/custom_fields/edit").to route_to(
      controller: "integrations/servicetitan/custom_fields",
      action: "edit"
    )
  end

  it "routes /integrations/servicetitan/custom_fields to integrations/servicetitan/custom_fields#update" do
    expect(patch: "/integrations/servicetitan/custom_fields").to route_to(
      controller: "integrations/servicetitan/custom_fields",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/custom_fields to integrations/servicetitan/custom_fields#update" do
    expect(put: "/integrations/servicetitan/custom_fields").to route_to(
      controller: "integrations/servicetitan/custom_fields",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/custom_fields to integrations/servicetitan/custom_fields#index" do
    expect(get: "/integrations/servicetitan/custom_fields").to route_to(
      controller: "integrations/servicetitan/custom_fields",
      action: "index"
    )
  end

  it "routes /integrations/servicetitan/employees to integrations/servicetitan/employees#show" do
    expect(get: "/integrations/servicetitan/employees").to route_to(
      controller: "integrations/servicetitan/employees",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/employees to integrations/servicetitan/employees#update" do
    expect(patch: "/integrations/servicetitan/employees").to route_to(
      controller: "integrations/servicetitan/employees",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/employees to integrations/servicetitan/employees#update" do
    expect(put: "/integrations/servicetitan/employees").to route_to(
      controller: "integrations/servicetitan/employees",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/import to integrations/servicetitan/imports#show" do
    expect(get: "/integrations/servicetitan/import").to route_to(
      controller: "integrations/servicetitan/imports",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/import to integrations/servicetitan/imports#update" do
    expect(patch: "/integrations/servicetitan/import").to route_to(
      controller: "integrations/servicetitan/imports",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/import to integrations/servicetitan/imports#update" do
    expect(put: "/integrations/servicetitan/import").to route_to(
      controller: "integrations/servicetitan/imports",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/instructions to integrations/servicetitan/instructions#show" do
    expect(get: "/integrations/servicetitan/instructions").to route_to(
      controller: "integrations/servicetitan/instructions",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/job_arrivals to integrations/servicetitan/job_arrivals#show" do
    expect(get: "/integrations/servicetitan/job_arrivals").to route_to(
      controller: "integrations/servicetitan/job_arrivals",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/job_arrivals to integrations/servicetitan/job_arrivals#update" do
    expect(patch: "/integrations/servicetitan/job_arrivals").to route_to(
      controller: "integrations/servicetitan/job_arrivals",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/job_arrivals to integrations/servicetitan/job_arrivals#update" do
    expect(put: "/integrations/servicetitan/job_arrivals").to route_to(
      controller: "integrations/servicetitan/job_arrivals",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/job_classifications to integrations/servicetitan/job_classifications#show" do
    expect(get: "/integrations/servicetitan/job_classifications").to route_to(
      controller: "integrations/servicetitan/job_classifications",
      action: "show"
    )
  end

  it "routes /integrations/servicetitan/job_classifications to integrations/servicetitan/job_classifications#update" do
    expect(patch: "/integrations/servicetitan/job_classifications").to route_to(
      controller: "integrations/servicetitan/job_classifications",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/job_classifications to integrations/servicetitan/job_classifications#update" do
    expect(put: "/integrations/servicetitan/job_classifications").to route_to(
      controller: "integrations/servicetitan/job_classifications",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/minimum_job_fees/edit to integrations/servicetitan/minimum_job_fees#edit" do
    expect(get: "/integrations/servicetitan/minimum_job_fees/edit").to route_to(
      controller: "integrations/servicetitan/minimum_job_fees",
      action: "edit"
    )
  end

  it "routes /integrations/servicetitan/minimum_job_fees to integrations/servicetitan/minimum_job_fees#update" do
    expect(patch: "/integrations/servicetitan/minimum_job_fees").to route_to(
      controller: "integrations/servicetitan/minimum_job_fees",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/minimum_job_fees to integrations/servicetitan/minimum_job_fees#update" do
    expect(put: "/integrations/servicetitan/minimum_job_fees").to route_to(
      controller: "integrations/servicetitan/minimum_job_fees",
      action: "update"
    )
  end

  it "routes /integrations/servicetitan/regions to integrations/servicetitan/regions#index" do
    expect(get: "/integrations/servicetitan/regions").to route_to(
      controller: "integrations/servicetitan/regions",
      action: "index"
    )
  end

  it "routes /integrations/servicetitan/regions to integrations/servicetitan/regions#create" do
    expect(post: "/integrations/servicetitan/regions").to route_to(
      controller: "integrations/servicetitan/regions",
      action: "create"
    )
  end

  it "routes /integrations/servicetitan/regions/:region/edit to integrations/servicetitan/regions#edit" do
    expect(get: "/integrations/servicetitan/regions/1/edit").to route_to(
      controller: "integrations/servicetitan/regions",
      action: "edit",
      region: "1"
    )
  end

  it "routes /integrations/servicetitan/regions/:region to integrations/servicetitan/regions#update" do
    expect(patch: "/integrations/servicetitan/regions/1").to route_to(
      controller: "integrations/servicetitan/regions",
      action: "update",
      region: "1"
    )
  end

  it "routes /integrations/servicetitan/regions/:region to integrations/servicetitan/regions#update" do
    expect(put: "/integrations/servicetitan/regions/1").to route_to(
      controller: "integrations/servicetitan/regions",
      action: "update",
      region: "1"
    )
  end

  it "routes /integrations/servicetitan/regions/:region to integrations/servicetitan/regions#destroy" do
    expect(delete: "/integrations/servicetitan/regions/1").to route_to(
      controller: "integrations/servicetitan/regions",
      action: "destroy",
      region: "1"
    )
  end

  it "routes /integrations/servicetitan/trades to integrations/servicetitan/trades#index" do
    expect(get: "/integrations/servicetitan/trades").to route_to(
      controller: "integrations/servicetitan/trades",
      action: "index"
    )
  end

  it "routes /integrations/servicetitan/trades to integrations/servicetitan/trades#create" do
    expect(post: "/integrations/servicetitan/trades").to route_to(
      controller: "integrations/servicetitan/trades",
      action: "create"
    )
  end

  it "routes /integrations/servicetitan/trades/:trade/edit to integrations/servicetitan/trades#edit" do
    expect(get: "/integrations/servicetitan/trades/1/edit").to route_to(
      controller: "integrations/servicetitan/trades",
      action: "edit",
      trade: "1"
    )
  end

  it "routes /integrations/servicetitan/trades/:trade to integrations/servicetitan/trades#update" do
    expect(patch: "/integrations/servicetitan/trades/1").to route_to(
      controller: "integrations/servicetitan/trades",
      action: "update",
      trade: "1"
    )
  end

  it "routes /integrations/servicetitan/trades/:trade to integrations/servicetitan/trades#update" do
    expect(put: "/integrations/servicetitan/trades/1").to route_to(
      controller: "integrations/servicetitan/trades",
      action: "update",
      trade: "1"
    )
  end

  it "routes /integrations/servicetitan/trades/:trade to integrations/servicetitan/trades#destroy" do
    expect(delete: "/integrations/servicetitan/trades/1").to route_to(
      controller: "integrations/servicetitan/trades",
      action: "destroy",
      trade: "1"
    )
  end
end
