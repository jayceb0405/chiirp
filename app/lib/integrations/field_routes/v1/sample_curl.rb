# frozen_string_literal: true

# app/lib/integrations/field_routes/v1/employees.rb
module Integrations
  module FieldRoutes
    module V1
      module SampleCurl
        # curl 'https://demo.pestroutes.com/api/customer/search' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Sec-Fetch-Mode: cors' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'dateUpdated%5Boperator%5D=%3E&dateUpdated%5Bvalue%5D=2019-09-27+00%3A00%3A00&authenticationKey=xxx&authenticationToken=xxx' --compressed
        # curl 'https://demo.pestroutes.com/api/import/main' -H 'Accept: application/json, text/javascript, */*; q=0.01'-H 'Sec-Fetch-Mode: cors' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'dataMain%5B0%5D%5BCustomerID%5D=PestRoutesTesting1234&dataMain%5B0%5D%5BBranch%5D=Demo+Pest+Control&dataMain%5B0%5D%5BCustomerName%5D=PestRoutes+Testing01&dataMain%5B0%5D%5BCustomerAddress%5D=Walt+Disney+World+Resort%2C+Orlando%2C+FL+32830&dataMain%5B0%5D%5BCustomerCity%5D=Orlando&dataMain%5B0%5D%5BCustomerState%5D=FL&dataMain%5B0%5D%5BCustomerZipCode%5D=32830&dataMain%5B0%5D%5BCustomerPhone1%5D=4428675309&dataMain%5B0%5D%5BCustomerPhone2%5D=4438675309&dataMain%5B0%5D%5BCustomerEmail%5D=&dataMain%5B0%5D%5BCustomerStatus%5D=INA&authenticationKey=xxx&authenticationToken=xxx' --compressed
        # curl 'https://demo.pestroutes.com/api/customer/get' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Sec-Fetch-Mode: cors' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' --data 'customerIDs%5B%5D=12&authenticationKey=xxx&authenticationToken=xxx' --compressed
      end
    end
  end
end
