# frozen_string_literal: true

# app/lib/integrations/job_ber/v20220915/clients.rb
module Integrations
  module JobBer
    module V20220915
      module Clients
        # call Jobber API for a client
        # jb_client.client()
        #   (req) jobber_client_id: (String)
        def client(jobber_client_id)
          reset_attributes
          @result = {}

          if jobber_client_id.blank?
            @message = 'Jobber client ID is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              query {
                client(id: "#{jobber_client_id}") {
                  companyName
                  firstName
                  lastName
                  isCompany
                  balance
                  billingAddress {
                    street1
                    street2
                    city
                    postalCode
                    province
                    country
                  }
                  phones {
                    id
                    number
                    primary
                    smsAllowed
                    description
                  }
                  emails {
                    id
                    address
                  }
                  tags {
                    nodes {
                      label
                    }
                  }
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

          jobber_request(
            body:,
            error_message_prepend: 'Integrations::JobBer::V20220915::Clients.client',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) ? @result.dig(:data, :client) : nil) || {}
        end
        # example Jobber client
        # {
        #   "data": {
        #     "client": {
        #       "companyName": "Jane's Automotive",
        #       "firstName": "Jane",
        #       "lastName": "Doe",
        #       "isCompany": false,
        #       "balance": 0,
        #       "billingAddress": null,
        #       "phones": [
        #         {
        #           "id": "Z2lkOi8vSm9iYmVyL0NsaWVudFBob25lTnVtYmVyLzcxNjYwMTE4",
        #           "number": "8023455136",
        #           "primary": true,
        #           "smsAllowed": true,
        #           "description": "Mobile"
        #         }
        #       ],
        #       "emails": [
        #         {
        #           "id": "Z2lkOi8vSm9iYmVyL0VtYWlsLzUxMTQ4OTM4",
        #           "address": "jane.doe@example.com"
        #         }
        #       ],
        #       "tags": {
        #         "nodes": []
        #       }
        #     }
        #   },
        #   "extensions": {
        #     "cost": {
        #       "requestedQueryCost": 122,
        #       "actualQueryCost": 16,
        #       "throttleStatus": {
        #         "maximumAvailable": 10000,
        #         "currentlyAvailable": 9984,
        #         "restoreRate": 500
        #       }
        #     },
        #     "versioning": {
        #       "version": "2023-08-18"
        #     }
        #   }
        # }

        # call Jobber API to create a client
        # jb_client.client_create()
        #   (req) contact: (Hash)
        def client_create(contact)
          reset_attributes
          @result = {}

          if !contact.is_a?(Hash) || contact.blank?
            @message = 'Contact is required.'
            return @result
          end

          body = {
            query: <<-GRAPHQL.squish
              mutation {
                clientCreate(
                  input: {
                    firstName: "#{contact.dig(:firstname)}",
                    lastName: "#{contact.dig(:lastname)}",
                    companyName: "#{contact.dig(:companyname)}",
                    emails: #{self.array_to_graphql(self.emails_to_add({}, contact))},
                    phones: #{self.array_to_graphql(self.phones_to_add({}, contact))},
                  }
                ) {
                  client {
                    id
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
            error_message_prepend: 'Integrations::JobBer::V20220915::Clients.client_create',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) && @result.dig(:data, :clientCreate, :userErrors).blank? ? @result.dig(:data, :clientCreate, :client, :id) : nil).to_s
        end

        # call Jobber API to edit a client
        # jb_client.client_update()
        #   (req) contact:          (Hash)
        #   (req) jobber_client_id: (String)
        def client_update(jobber_client_id, contact)
          reset_attributes
          @result = {}

          if jobber_client_id.blank?
            @message = 'Jobber client ID is required.'
            return @result
          elsif !contact.is_a?(Hash) || contact.blank?
            @message = 'Contact is required.'
            return @result
          end

          jobber_client = self.client(jobber_client_id)

          body = {
            query: <<-GRAPHQL.squish
              mutation {
                clientEdit(
                clientId: "#{jobber_client_id}",
                  input: {
                    firstName: "#{contact.dig(:firstname)}",
                    lastName: "#{contact.dig(:lastname)}",
                    companyName: "#{contact.dig(:companyname)}",
                    emailsToAdd: #{self.array_to_graphql(self.emails_to_add(jobber_client, contact))},
                    emailsToEdit: #{self.array_to_graphql(self.emails_to_edit(jobber_client, contact))},
                    phonesToAdd: #{self.array_to_graphql(self.phones_to_add(jobber_client, contact))},
                    phonesToEdit: #{self.array_to_graphql(self.phones_to_edit(jobber_client, contact))}
                  }
                ) {
                  client {
                    id
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
            error_message_prepend: 'Integrations::JobBer::V20220915::Clients.client_update',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          @result = (@result.is_a?(Hash) && @result.dig(:data, :clientEdit, :userErrors).blank? ? @result.dig(:data, :clientEdit, :client, :id) : nil).to_s
        end

        # call Jobber API for clients
        # jb_client.clients()
        #   (opt) end_cursor: (String)
        #   (opt) filter:     (Hash)
        #   (opt) page_size:  (Integer)
        def clients(args = {})
          reset_attributes
          @result     = { result: [], end_cursor: '' }
          @end_cursor = args.dig(:end_cursor).to_s

          body = {
            query: <<-GRAPHQL.squish
              query {
                clients(
                  first: #{(args.dig(:page_size) || 100).to_i},
                  after: "#{@end_cursor}",
                  filter: #{self.hash_to_graphql(args.dig(:filter) || {})}
                ) {
                  nodes {
                    id
                    name
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
            error_message_prepend: 'Integrations::JobBer::V20220915::Clients.clients',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   api_url
          )

          sleep_before_throttling(@result.dig(:extensions), @result.dig(:extensions, :cost, :actualQueryCost))

          @end_cursor   = @result.dig(:data, :clients, :pageInfo, :endCursor).to_s
          @more_results = @result.dig(:data, :clients, :pageInfo, :hasNextPage).to_bool
          @result       = (@result.dig(:data, :clients, :nodes) || []).compact_blank
        end

        private

        def emails_to_add(jobber_client, contact)
          if contact.dig(:email).present? && (jobber_client.dig(:emails).blank? || jobber_client[:emails].find { |email| email.dig(:address).to_s == contact.dig(:email).to_s }.blank?)
            [{ description: :MAIN, primary: true, address: contact.dig(:email).to_s }]
          else
            []
          end
        end

        def emails_to_edit(jobber_client, contact)
          if contact.dig(:email).present? && jobber_client.dig(:emails).present? && (email = jobber_client[:emails].find { |e| e.dig(:address).to_s == contact.dig(:email).to_s }).present?
            [{ id: email.dig(:id).to_s, description: :MAIN, primary: true, address: contact.dig(:email).to_s }]
          else
            []
          end
        end

        def phones_to_add(jobber_client, contact)
          phones = []

          (contact.dig(:phone_numbers) || []).each do |phone_number|
            if jobber_client.dig(:phones).blank? || jobber_client[:phones].find { |phone| phone.dig(:number).to_s == phone_number.dig(:phone).to_s }.blank?
              phones << { description: phone_number.dig(:label).to_s.upcase.to_sym, number: phone_number.dig(:phone).to_s, primary: phone_number.dig(:primary).to_bool, smsAllowed: contact.dig(:ok2text).nil? ? true : contact.dig(:ok2text).to_bool }
            end
          end

          phones
        end

        def phones_to_edit(jobber_client, contact)
          phones = []

          (contact.dig(:phone_numbers) || []).each do |phone_number|
            if jobber_client.dig(:phones).present? && (phone = jobber_client[:phones].find { |p| p.dig(:number).to_s == phone_number.dig(:phone).to_s }).present?
              phones << { id: phone.dig(:id).to_s, description: phone_number.dig(:label).to_s.upcase.to_sym, number: phone_number.dig(:phone).to_s, primary: phone_number.dig(:primary).to_bool, smsAllowed: contact.dig(:ok2text).nil? ? true : contact.dig(:ok2text).to_bool }
            end
          end

          phones
        end
      end
    end
  end
end
