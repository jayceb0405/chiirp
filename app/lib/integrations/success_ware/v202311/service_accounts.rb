# frozen_string_literal: true

# app/lib/integrations/success_ware/v202311/service_accounts.rb
module Integrations
  module SuccessWare
    module V202311
      module ServiceAccounts
        # call Successware API for a service account (customer)
        # sw_client.service_account()
        #   (req) successware_customer_id: (String)
        def customer(successware_customer_id)
          reset_attributes
          @result = {}

          if successware_customer_id.to_i.zero? || successware_customer_id.to_i.negative?
            @message = 'Successware service account ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                searchServiceAccounts(page: 0, size: 1, input: { customerId: #{successware_customer_id.to_i} }) {
                  content {
                    id
                    customer {
                      id
                      firstName
                      lastName
                      phoneNumber
                      email
                      leadSource
                      leadSourceId
                      noEmail
                      phone2
                      phone3
                      phone4
                      leadSourceDescription
                      commercial
                      companyName
                    }
                    serviceLocations {
                      id
                      address1
                      address2
                      city
                      state
                      zipCode
                      type
                      companyName
                      contractArBillingCustomerId
                    }
                    primaryBillingAddress {
                      balanceDue
                    }
                    billingAccountOutput {
                      mainArBillingCustomer {
                        balanceDue
                      }
                    }
                  }
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                  totalElements
                  totalPages
                  pageSize
                  pageNumber
                  numberOfElements
                }
              }
            GRAPHQL
          }
          #   customFields {
          #   ... on CustomFieldArea {
          #     id
          #     label
          #   }
          #   ... on CustomFieldText {
          #     id
          #     label
          #   }
          #   ... on CustomFieldBoolean {
          #     id
          #     label
          #   }
          #   ... on CustomFieldLink {
          #     id
          #     label
          #   }
          #   ... on CustomFieldNumber {
          #     id
          #     label
          #   }
          #   ... on CustomFieldSelect {
          #     id
          #     label
          #   }
          # }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::ServiceAccounts.customer',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result  = (@result.is_a?(Hash) && @result.dig(:successful).to_bool && @result.dig(:data, :searchServiceAccounts, :content))&.first || {}
          @success = @result.present?

          @result
        end
        # example Successware customer data received
        # {
        #   "data": {
        #     "searchServiceAccounts": {
        #       "content": [
        #         {
        #           "id":"1716257030",
        #           "customer": {
        #             "id":"1716257030",
        #             "firstName":"Ching",
        #             "lastName":"Blackerby",
        #             "phoneNumber":"5556385822",
        #             "email":null,
        #             "leadSource":"Ref -O",
        #             "leadSourceId":"1716000552",
        #             "noEmail":false,
        #             "phone2":"555-638-5822",
        #             "phone3":null,
        #             "phone4":null,
        #             "leadSourceDescription":"Referred by others ???",
        #             "commercial":false,
        #             "companyName":null
        #           },
        #           "serviceLocations": [
        #             {
        #               "id":"1716257030",
        #               "address1":"6362 Rolling Dale Ct",
        #               "address2":null,
        #               "city":"Brewerton",
        #               "state":"NY",
        #               "zipCode":"13039",
        #               "type":"Residential",
        #               "companyName":null,
        #               "contractArBillingCustomerId":null
        #             }
        #           ],
        #           "primaryBillingAddress":null,
        #           "billingAccountOutput": {
        #             "mainArBillingCustomer": [
        #               {"balanceDue":0.0}
        #             ]
        #           }
        #         }
        #       ],
        #       "successful":true,
        #       "message":"Fetched successfully.",
        #       "errors":null,
        #       "totalElements":1,
        #       "totalPages":1,
        #       "pageSize":1,
        #       "pageNumber":0,
        #       "numberOfElements":1
        #     }
        #   }
        # }

        # call Successware API to create a service_account (customer)
        # sw_client.customer_create()
        #   (req) contact_hash: (Hash)
        def customer_create(contact_hash)
          reset_attributes
          @result = {}

          if !contact_hash.is_a?(Hash) || contact_hash.blank?
            @message = 'Contact is required.'
            return @result
          elsif contact_hash.dig(:address1).blank?
            @message = 'Address line 1 is required.'
            return @result
          elsif contact_hash.dig(:city).blank?
            @message = 'Address city is required.'
            return @result
          elsif contact_hash.dig(:state).blank?
            @message = 'Address state is required.'
            return @result
          elsif contact_hash.dig(:zipcode).blank?
            @message = 'Address zipcode is required.'
            return @result
          elsif contact_hash.dig(:phone_numbers).blank?
            @message = 'At least 1 Contact phone number is required.'
            return @result
          elsif contact_hash.dig(:email).blank?
            @message = 'Email address is required.'
            return @result
          elsif contact_hash.dig(:customer_type).blank?
            @message = 'Successware customer type is required.'
            return @result
          elsif contact_hash.dig(:lead_source_id).blank?
            @message = 'Successware lead source ID is required.'
            return @result
          elsif contact_hash.dig(:lead_source_type_id).blank?
            @message = 'Successware lead source type ID is required.'
            return @result
          end

          phones = self.phones(0, contact_hash)

          body = {
            query: <<-GRAPHQL.squish
              mutation {
                createServiceAccount(
                  input: {
                    customer: {
                      firstName: "#{contact_hash.dig(:firstname)}"
                      lastName: "#{contact_hash.dig(:lastname)}"
                      companyName: "#{contact_hash.dig(:customer_type).casecmp?('commercial') ? contact_hash.dig(:companyname) : ''}"
                      phoneNumber: "#{phones[1]}"
                      phone2: "#{phones[2]}"
                      phone3: "#{phones[3]}"
                      phone4: "#{phones[4]}"
                      email: "#{contact_hash.dig(:email)}"
                      noEmail: #{!contact_hash.dig(:ok2email).to_bool}
                      commercial: #{contact_hash.dig(:customer_type).casecmp?('commercial')}
                      leadSourceId: #{contact_hash.dig(:lead_source_id).to_i}
                      leadSourceTypeId: #{contact_hash.dig(:lead_source_type_id).to_i}
                    }
                    location: {
                      companyName: "#{contact_hash.dig(:customer_type).casecmp?('commercial') ? contact_hash.dig(:companyname) : ''}"
                      address1: "#{contact_hash.dig(:address1)}"
                      address2: "#{contact_hash.dig(:address2)}"
                      city: "#{contact_hash.dig(:city)}"
                      state: "#{contact_hash.dig(:state)}"
                      zipCode: "#{contact_hash.dig(:zipcode)}"
                      type: "#{contact_hash.dig(:customer_type)}"
                    }
                  }
                ) {
                  successful
                  message
                  serviceAccount {
                    customerId
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::ServiceAccounts.customer_create',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @success = (@result.is_a?(Hash) && @result.dig(:data, :createServiceAccount, :successful)).to_bool
          @message = @result.dig(:data, :createServiceAccount, :errors, :errorMessage) unless @success
          @result  = (@result.is_a?(Hash) && @result.dig(:data, :createServiceAccount, :serviceAccount, :customerId)).presence.to_i

          @result
        end
        # sample Successware response
        # {
        #   "data": {
        #     "createServiceAccount": {
        #       "successful": true,
        #       "message": "CREATED SUCCESSFULLY",
        #       "serviceAccount": {
        #         "id": "539883236437249478",
        #         "customerId": "539883236436987334",
        #         "locationId": "539883235094662598"
        #       },
        #       "errors": null
        #     }
        #   }
        # }

        # call Successware API to edit a customer
        # sw_client.customer_update()
        #   (req) contact_hash:            (Hash)
        #   (req) successware_customer_id: (String)
        def customer_update(successware_customer_id, contact_hash)
          reset_attributes
          @result = {}

          if successware_customer_id.blank?
            @message = 'Successware customer ID is required.'
            return @result
          elsif !contact_hash.is_a?(Hash) || contact_hash.blank?
            @message = 'Contact is required.'
            return @result
          elsif contact_hash.dig(:phone_numbers).blank?
            @message = 'At least 1 Contact phone number is required.'
            return @result
          elsif contact_hash.dig(:email).blank?
            @message = 'Email address is required.'
            return @result
          end

          # successware_client = self.client(successware_customer_id)
          phones = self.phones(successware_customer_id, contact_hash)

          body = {
            query: <<-GRAPHQL.squish
              mutation {
                updateServiceAccount(
                  input: {
                    id: #{self.successware_customer(successware_customer_id).dig(:id)}
                    customer: {
                      id: #{successware_customer_id.to_i}
                      firstName: "#{contact_hash.dig(:firstname)}"
                      lastName: "#{contact_hash.dig(:lastname)}"
                      companyName: "#{contact_hash.dig(:customer_type).casecmp?('commercial') ? contact_hash.dig(:companyname) : ''}"
                      phoneNumber: "#{phones[1]}"
                      phone2: "#{phones[2]}"
                      phone3: "#{phones[3]}"
                      phone4: "#{phones[4]}"
                      email: "#{contact_hash.dig(:email)}"
                      noEmail: #{!contact_hash.dig(:ok2email).to_bool}
                      commercial: #{contact_hash.dig(:customer_type).casecmp?('commercial')}
                    }
                    serviceLocation: {
                      id: #{self.successware_customer(successware_customer_id).dig(:serviceLocations)&.first&.dig(:id)}
                      companyName: "#{contact_hash.dig(:customer_type).casecmp?('commercial') ? contact_hash.dig(:companyname) : ''}"
                      address1: "#{contact_hash.dig(:address1)}"
                      address2: "#{contact_hash.dig(:address2)}"
                      city: "#{contact_hash.dig(:city)}"
                      state: "#{contact_hash.dig(:state)}"
                      zipCode: "#{contact_hash.dig(:zipcode)}"
                      type: "#{contact_hash.dig(:customer_type)}"
                      ownerOccupied: true
                    }
                  }
                )
                {
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::ServiceAccounts.customer_update',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @success = (@result.is_a?(Hash) && @result.dig(:data, :updateServiceAccount, :successful)).to_bool
          @message = @result.dig(:data, :updateServiceAccount, :message) unless @success
          @result  = @success

          @result
        end
        # sample Successware response
        # {
        #   "data": {
        #     "updateServiceAccount": {
        #       "successful": true,
        #       "message": "UPDATE SUCCESSFUL",
        #       "errors": null
        #     }
        #   }
        # }

        # call Successware API for service accounts (customers)
        # sw_client.customers()
        #   (opt) filter: (Hash)
        #   (opt) page:   (Integer) first page = 0
        def customers(args = {})
          reset_attributes
          @result = []

          body = {
            query: <<-GRAPHQL.squish
              query {
                searchServiceAccounts(page: #{args.dig(:page).to_i}, size: #{Integrations::SuccessWare::V202311::Base::PAGE_SIZE}, input: #{args.dig(:filter).presence || {}}) {
                  content {
                    id
                    customer {
                      id
                      firstName
                      lastName
                      phoneNumber
                      email
                      leadSource
                      leadSourceId
                      noEmail
                      phone2
                      phone3
                      phone4
                      leadSourceDescription
                      commercial
                      companyName
                    }
                    serviceLocations {
                      id
                      address1
                      address2
                      city
                      state
                      zipCode
                      type
                      companyName
                      contractArBillingCustomerId
                    }
                    primaryBillingAddress {
                      balanceDue
                    }
                    billingAccountOutput {
                      mainArBillingCustomer {
                        balanceDue
                      }
                    }
                  }
                  successful
                  message
                  errors {
                    path
                    errorMessage
                  }
                  totalElements
                  totalPages
                  pageSize
                  pageNumber
                  numberOfElements
                }
              }
            GRAPHQL
          }

          successware_request(
            body:,
            error_message_prepend: 'Integrations::SuccessWare::V202311::ServiceAccounts.customers',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          # sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))

          @result = (@result.dig(:data, :searchServiceAccounts) || []).compact_blank
        end
        # Successware response ex:
        # {
        #   "data": {
        #     "searchServiceAccounts": {
        #       "content": [
        #         {
        #           "id":"1716257030",
        #           "customer": {
        #             "id":"1716257030",
        #             "firstName":"Ching",
        #             "lastName":"Blackerby",
        #             "phoneNumber":"5556385822",
        #             "email":null,
        #             "leadSource":"Ref -O",
        #             "leadSourceId":"1716000552",
        #             "noEmail":false,
        #             "phone2":"555-638-5822",
        #             "phone3":null,
        #             "phone4":null,
        #             "leadSourceDescription":"Referred by others ???",
        #             "commercial":false,
        #             "companyName":null
        #           },
        #           "serviceLocations": [
        #             {
        #               "id":"1716257030",
        #               "address1":"6362 Rolling Dale Ct",
        #               "address2":null,
        #               "city":"Brewerton",
        #               "state":"NY",
        #               "zipCode":"13039",
        #               "type":"Residential",
        #               "companyName":null,
        #               "contractArBillingCustomerId":null
        #             }
        #           ],
        #           "primaryBillingAddress":null,
        #           "billingAccountOutput": {
        #             "mainArBillingCustomer": [
        #               {"balanceDue":0.0}
        #             ]
        #           }
        #         }
        #       ],
        #       "successful":true,
        #       "message":"Fetched successfully.",
        #       "errors":null,
        #       "totalElements":1,
        #       "totalPages":1,
        #       "pageSize":1,
        #       "pageNumber":0,
        #       "numberOfElements":1
        #     }
        #   }
        # }
        # response ex:
        # {
        #   :content=>[
        #     {
        #       :id=>"1716257300",
        #       :customer=>{
        #         :id=>"1716257300",
        #         :firstName=>"Delbert",
        #         :lastName=>"Simha",
        #         :phoneNumber=>"5551307697",
        #         :email=>nil,
        #         :leadSource=>nil,
        #         :leadSourceId=>nil,
        #         :noEmail=>false,
        #         :phone2=>"555-130-7697",
        #         :phone3=>nil,
        #         :phone4=>nil,
        #         :leadSourceDescription=>nil,
        #         :commercial=>false,
        #         :companyName=>nil
        #       },
        #       :serviceLocations=>[
        #         {
        #           :id=>"1716257300",
        #           :address1=>"2084 Texana Way",
        #           :address2=>"",
        #           :city=>"Long Island",
        #           :state=>"NY",
        #           :zipCode=>"11101",
        #           :type=>"",
        #           :companyName=>nil,
        #           :contractArBillingCustomerId=>nil
        #         }
        #       ],
        #       :primaryBillingAddress=>nil,
        #       :billingAccountOutput=>{:mainArBillingCustomer=>nil}
        #     }...,
        #   ],
        #   :successful=>true,
        #   :message=>"Fetched successfully.",
        #   :totalElements=>256326,
        #   :totalPages=>513,
        #   :pageSize=>500,
        #   :pageNumber=>1,
        #   :numberOfElements=>500
        # }

        # private

        def emails_to_add(successware_client, contact)
          if contact.dig(:email).present? && (successware_client.dig(:emails).blank? || successware_client[:emails].find { |email| email.dig(:address).to_s == contact.dig(:email).to_s }.blank?)
            [{ description: :MAIN, primary: true, address: contact.dig(:email).to_s }]
          else
            []
          end
        end

        def emails_to_edit(successware_client, contact)
          if contact.dig(:email).present? && successware_client.dig(:emails).present? && (email = successware_client[:emails].find { |e| e.dig(:address).to_s == contact.dig(:email).to_s }).present?
            [{ id: email.dig(:id).to_s, description: :MAIN, primary: true, address: contact.dig(:email).to_s }]
          else
            []
          end
        end

        def phones(successware_customer_id, contact_hash)
          phones = [self.successware_customer(successware_customer_id).dig(:content, :customer, :phoneNumber).to_s, self.successware_customer(successware_customer_id).dig(:content, :customer, :phone2).to_s, self.successware_customer(successware_customer_id).dig(:content, :customer, :phone3).to_s, self.successware_customer(successware_customer_id).dig(:content, :customer, :phone4).to_s]

          (contact_hash.dig(:phone_numbers)&.map { |p| p.dig(:phone) }&.- phones).each do |phone|
            if phones[0].blank?
              phones[0] = phone
            elsif phones[1].blank?
              phones[1] = phone
            elsif phones[2].blank?
              phones[2] = phone
            elsif phones[3].blank?
              phones[3] = phone
            end
          end

          phones
        end

        def successware_customer(successware_customer_id)
          @successware_customer = @successware_customer.present? && @successware_customer.dig(:customer, :id).to_i == successware_customer_id.to_i ? @successware_customer : self.customer(successware_customer_id)
        end
      end
    end
  end
end
