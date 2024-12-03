# frozen_string_literal: true

# app/lib/integrations/job_ber/v20231115/clients.rb
module Integrations
  module JobBer
    module V20231115
      module Properties
        # return a property that belongs to a Jobber client
        # jb_client.property()
        #   (req) jobber_property_id: (String)
        def property(jobber_property_id)
          reset_attributes
          @result = {}

          if jobber_property_id.blank?
            @message = 'Jobber property ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                property(id: "#{jobber_property_id}") {
                  id
                  address {
                    street1
                    street2
                    city
                    province
                    postalCode
                  }
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20231115::Properties.property',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :property) : nil) || {}
        end
        # example @result
        # {
        #   id:      'Z2lkOi8vSm9iYmVyL1Byb3BlcnR5Lzk3OTcyMDY1',
        #   address: {
        #     street1:    '125 Main Street',
        #     street2:    'Suite B',
        #     city:       'Big City',
        #     province:   'GA',
        #     postalCode: '31405'
        #   }
        # }
        # example successful Jobber response
        # {
        #   "data": {
        #     "property": {
        #       "id": "Z2lkOi8vSm9iYmVyL1Byb3BlcnR5Lzk3OTcyMDY1",
        #       "address": {
        #         "street1": "125 Main Street",
        #         "street2": "Suite B",
        #         "city": "Big City",
        #         "province": "GA",
        #         "postalCode": "31405"
        #       }
        #     }
        #   },
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 8,
        #       "actualQueryCost": 8,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 9992,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2024-06-10"
        #     }
        #   }
        # }
        # example unsuccessful Jobber response
        # {
        #   "errors": [
        #     {
        #       "message": "'2lkOi8vSm9iYmVyL1Byb3BlcnR5Lzk3OTcyMDY1' is not a valid EncodedId",
        #       "locations": [
        #         {
        #           "line": 2,
        #           "column": 17
        #         }
        #       ],
        #       "path": [
        #         "query",
        #         "property",
        #         "id"
        #       ],
        #       "extensions": {
        #         "code": "argumentLiteralsIncompatible",
        #         "typeName": "CoercionError"
        #       }
        #     }
        #   ],
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 0,
        #       "actualQueryCost": 0,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 10000,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2024-06-10"
        #     }
        #   }
        # }

        # call Jobber API to create a property for a client
        # jb_client.property_create()
        #   (req) contact: (Hash)
        #   (req) jobber_client_id: (String)
        def property_create(**args)
          reset_attributes
          @result = {}

          if args.dig(:jobber_client_id).blank?
            @message = 'Jobber client ID is required.'
            return @result
          elsif !args.dig(:contact).is_a?(Hash) || args.dig(:contact).blank?
            @message = 'Contact is required.'
            return @result
          elsif args[:contact].dig(:address1).blank? || args[:contact].dig(:city).blank? || args[:contact].dig(:state).blank? || args[:contact].dig(:zip).blank?
            @message = 'Contact address, city, state, and zip are required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              mutation {
                propertyCreate(
                  clientId: "#{args[:jobber_client_id]}",
                  input: {properties: [{
                    address: {
                      street1: "#{args[:contact].dig(:address1)}",
                      street2: "#{args[:contact].dig(:address2)}",
                      city: "#{args[:contact].dig(:city)}",
                      province: "#{args[:contact].dig(:state)}",
                      postalCode:"#{args[:contact].dig(:zip)}"
                    }
                  }]}
                ) {
                  client {
                    id
                  }
                  properties {
                    id
                    address {
                      street1
                      street2
                      city
                      province
                      postalCode
                    }
                  }
                  userErrors {
                    message
                    path
                  }
                }
              }
            GRAPHQL
          }

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20231115::Clients.property_create',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) && @result.dig(:data, :propertyCreate, :userErrors).blank? ? @result.dig(:data, :propertyCreate, :client, :id) : nil).to_s
        end
        # example successful response
        # {
        #   "data": {
        #     "propertyCreate": {
        #       "client": {
        #         "id": "Z2lkOi8vSm9iYmVyL0NsaWVudC81OTYxNjQ1NQ=="
        #       },
        #       "properties": [
        #         {
        #           "id": "Z2lkOi8vSm9iYmVyL1Byb3BlcnR5Lzk3OTcyMDY1",
        #           "address": {
        #             "street1": "125 Main Street",
        #             "street2": "Suite B",
        #             "city": "Big City",
        #             "province": "GA",
        #             "postalCode": "31405"
        #           }
        #         }
        #       ],
        #       "userErrors": []
        #     }
        #   },
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 14,
        #       "actualQueryCost": 12,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 9988,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2024-06-10"
        #     }
        #   }
        # }
        # example failed response
        # {
        #   "data": {
        #     "propertyCreate": {
        #       "client": null,
        #       "properties": [],
        #       "userErrors": [
        #         {
        #           "message": "Property already exists",
        #           "path": [
        #             "input",
        #             "properties"
        #           ]
        #         }
        #       ]
        #     }
        #   },
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 14,
        #       "actualQueryCost": 6,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 9994,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2024-06-10"
        #     }
        #   }
        # }

        # return properties that belong to a Jobber client
        # jb_client.properties()
        #   (req) jobber_client_id: (String)
        def properties(jobber_client_id)
          reset_attributes
          @result  = {}
          response = []

          if jobber_client_id.blank?
            @message = 'Jobber client ID is required.'
            return @result
          end

          end_cursor = ''

          loop do
            body = {
              query: <<-GRAPHQL.squish
                query {
                  properties(
                    first: 100,
                    after: "#{end_cursor}",
                    filter: { clientId: "#{jobber_client_id}" }
                  ) {
                    nodes {
                      id
                      address {
                        street1
                        street2
                        city
                        province
                        postalCode
                      }
                    }
                    pageInfo {
                      endCursor
                      hasNextPage
                    }
                  }
                }
              GRAPHQL
            }

            jobber_request(
              body:,
              error_message_prepend: 'Integrations::JobBer::V20231115::Properties.properties',
              method:                'post',
              params:                nil,
              default_result:        {},
              url:                   api_url
            )

            sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))

            end_cursor   = @result.dig(:data, :properties, :pageInfo, :endCursor).to_s
            more_results = @result.dig(:data, :properties, :pageInfo, :hasNextPage).to_bool
            response += (@result.dig(:data, :properties, :nodes) || []).compact_blank

            break if !more_results || end_cursor.blank?
          end

          @result = response
        end
        # example @result
        # [
        #   { address: { street1: '101 State Place', street2: 'Suite 123', city: 'Rutland', province: 'Vermont', postalCode: '05701' } },
        #   { address: { street1: '101 Main Street', street2: 'Suite B', city: 'Big City', province: 'GA', postalCode: '31405' } },
        #   { address: { street1: '121 Main Street', street2: 'Suite B', city: 'Big City', province: 'GA', postalCode: '31405' } },
        #   { address: { street1: '125 Main Street', street2: 'Suite B', city: 'Big City', province: 'GA', postalCode: '31405' } }
        # ]
        # example successful Jobber response
        # {
        #   "data": {
        #     "properties": {
        #       "nodes": [
        #         {
        #           "address": {
        #             "id": "Z2lkOi8vSm9iYmVyL1Byb3BlcnR5QWRkcmVzcy85Nzk3MjA2NQ==",
        #             "street1": "125 Main Street",
        #             "street2": "Suite B",
        #             "city": "Big City",
        #             "province": "GA",
        #             "postalCode": "31405"
        #           }
        #         },
        #         {
        #           "address": {
        #             "id": "Z2lkOi8vSm9iYmVyL1Byb3BlcnR5QWRkcmVzcy85Nzk3MTg2Ng==",
        #             "street1": "121 Main Street",
        #             "street2": "Suite B",
        #             "city": "Big City",
        #             "province": "GA",
        #             "postalCode": "31405"
        #           }
        #         },
        #         {
        #           "address": {
        #             "id": "Z2lkOi8vSm9iYmVyL1Byb3BlcnR5QWRkcmVzcy85Nzk3MTM4MA==",
        #             "street1": "101 Main Street",
        #             "street2": "Suite B",
        #             "city": "Big City",
        #             "province": "GA",
        #             "postalCode": "31405"
        #           }
        #         },
        #         {
        #           "address": {
        #             "id": "Z2lkOi8vSm9iYmVyL1Byb3BlcnR5QWRkcmVzcy82NDU0MzQzMA==",
        #             "street1": "101 State Place",
        #             "street2": "Suite 123",
        #             "city": "Rutland",
        #             "province": "Vermont",
        #             "postalCode": "05701"
        #           }
        #         }
        #       ],
        #       "pageInfo": {
        #         "endCursor": "NA",
        #         "hasNextPage": false
        #       }
        #     }
        #   },
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 705,
        #       "actualQueryCost": 33,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 9967,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2024-06-10"
        #     }
        #   }
        # }
        # example unsuccessful Jobber response
        # {
        #   "errors": [
        #     {
        #       "message": "'2lkOi8vSm9iYmVyL0NsaWVudC81OTYxNjQ1NQ==' is not a valid EncodedId",
        #       "locations": [
        #         {
        #           "line": 5,
        #           "column": 29
        #         }
        #       ],
        #       "path": [
        #         "query",
        #         "properties",
        #         "filter",
        #         "clientId"
        #       ],
        #       "extensions": {
        #         "code": "argumentLiteralsIncompatible",
        #         "typeName": "CoercionError"
        #       }
        #     }
        #   ],
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 0,
        #       "actualQueryCost": 0,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 10000,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2024-06-10"
        #     }
        #   }
        # }
      end
    end
  end
end
