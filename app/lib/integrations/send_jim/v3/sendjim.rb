# frozen_string_literal: true

# app/lib/integrations/send_jim/v3/sendjim.rb
module Integrations
  module SendJim
    module V3
      # process various API calls to SendJim
      class Sendjim
        attr_reader :error, :faraday_result, :message, :result, :token

        # initialize SendJim
        # sj_client = Integrations::SendJim::V3::Sendjim.new()
        # (req) token: (String)
        def initialize(token)
          reset_attributes
          @result = nil
          @token  = token.to_s
        end

        # POST tag to a SendJim contact
        # sj_client.add_tag(ext_id)
        # (req) ext_id:   (Integer)
        # (req) tag_name: (String)
        def add_tag(args = {})
          reset_attributes
          @result = {}

          if args.dig(:ext_id).to_i.zero?
            @message = 'SendJim Contact ID is required.'
            return @result
          elsif args.dig(:tag_name).to_s.empty?
            @message = 'Tag name is required.'
            return @result
          end

          sendjim_request(
            body:                  { TagName: args[:tag_name].to_s },
            error_message_prepend: 'Integrations::SendJim::AddTag',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contact/#{args[:ext_id]}/tag"
          )

          @result = @result.dig(:Tags)

          unless @success && @result&.include?(args[:tag_name])
            @message = @message.presence || 'Tag application failed!'
            @success = false
          end

          @result
        end

        # GET SendJim contact
        # sj_client.contact(ext_id)
        # (opt) ext_id: (Integer)
        def contact(ext_id = nil)
          reset_attributes
          @result = {}

          if ext_id.to_i.zero?
            @message = 'SendJim Contact ID is required.'
            return @result
          end

          sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::Contact',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contact/#{ext_id}"
          )

          if @success && @result.dig(:Contact).present?
            @result = @result[:Contact]
          else
            @message = @message.presence || 'Contact was not found!'
            @result  = {}
            @success = false
          end

          @result
        end

        # GET SendJim contacts
        # sj_client.contacts(page)
        # (opt) page: (Integer)
        def contacts(page = 1)
          reset_attributes
          @result = {}

          @result = sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::Contacts',
            method:                'get',
            params:                { page: },
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contacts"
          ).dig(:Contacts)
        end

        # GET SendJim contacts
        # sj_client.contacts_count
        def contacts_count
          reset_attributes
          @result = {}

          sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::Contacts',
            method:                'get',
            params:                { page: 1 },
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contacts"
          )

          if @success && @result.dig(:TotalNumberOfContacts).to_i.positive?
            @result = @result[:TotalNumberOfContacts].to_i
          else
            @message = @message.presence || 'Contacts were not found!'
            @result  = 0
            @success = false
          end

          @result
        end

        # GET SendJim contacts
        # sj_client.contacts_pages
        def contacts_pages
          reset_attributes
          @result = {}

          sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::Contacts',
            method:                'get',
            params:                { page: 1 },
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contacts"
          )

          if @success && @result.dig(:TotalNumberOfPages).to_i.positive?
            @result = @result[:TotalNumberOfPages].to_i
          else
            @message = @message.presence || 'Contacts were not found!'
            @result  = 0
            @success = false
          end

          @result
        end

        # POST tag to a SendJim contact
        # sj_client.delete_tag(ext_id)
        # (req) ext_id:   (Integer)
        # (req) tag_name: (String)
        def delete_tag(args = {})
          reset_attributes
          @result = {}

          if args.dig(:ext_id).to_i.zero?
            @message = 'SendJim Contact ID is required.'
            return @result
          elsif args.dig(:tag_name).to_s.empty?
            @message = 'Tag name is required.'
            return @result
          end

          sendjim_request(
            body:                  { TagName: args[:tag_name].to_s },
            error_message_prepend: 'Integrations::SendJim::DeleteTag',
            method:                'delete',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contact/#{args[:ext_id]}/tag"
          )

          @result = @result.dig(:Tags)

          unless @success && @result&.exclude?(args[:tag_name])
            @message = @message.presence || 'Tag deletion failed!'
            @success = false
          end

          @result
        end

        # POST a Neighbor Quick Send Mailing by Contact or SendJim Contact ID
        # sj_client.neighbor_quick_send()
        # general data
        # (req) quick_send_id:    (Integer)
        # (opt) neighbor_count:   (Integer)
        # (opt) same_street_only: (Boolean)
        # posting by Contact data
        # (req) firstname:        (String)
        # (req) lastname:         (String)
        # (req) address_01:       (String)
        # (opt) address_02:       (String)
        # (req) city:             (String)
        # (opt) email:            (String)
        # (req) state:            (String)
        # (opt) phone_number:     (String)
        # (req) postal_code:      (String)
        # (opt) tag_names:        (Array)
        # posting by address/radius
        # (req) address_01:       (String)
        # (opt) address_02:       (String)
        # (req) city:             (String)
        # (req) state:            (String)
        # (req) postal_code:      (String)
        # (req) radius:           (float)
        # posting by SendJim Contact ID data
        # (req) ext_id:           (Integer)
        def neighbor_quick_send(args = {})
          reset_attributes
          @result = {}

          if args.dig(:quick_send_id).to_i.zero?
            @message = 'SendJim Quick Send ID is required.'
            return @result
          end

          if args.dig(:ext_id).to_i.positive?
            body = {
              ContactID:               args[:ext_id].to_i,
              NumberOfNeighborsToMail: (args.dig(:neighbor_count) || 20).to_i
            }
            target_url = 'neighbormailing'
          elsif args.dig(:radius).to_f.positive? && args.dig(:address_01).to_s.present? && args.dig(:city).to_s.present? && args.dig(:state).to_s.present? && args.dig(:postal_code).to_s.present?
            body = {
              ContactData:    {
                StreetAddress: [args[:address_01].to_s, args.dig(:address_02).to_s].compact_blank.join(', '),
                City:          args[:city].to_s,
                State:         args[:state].to_s,
                PostalCode:    args[:postal_code].to_s
              },
              RadiusInMeters: self.miles_to_meters(args[:radius].to_f)
            }
            target_url = 'neighbors-of-address-by-radius/quicksend'
          elsif args.dig(:firstname).to_s.present? && args.dig(:lastname).to_s.present? && args.dig(:address_01).to_s.present? && args.dig(:city).to_s.present? && args.dig(:state).to_s.present? && args.dig(:postal_code).to_s.present?
            body = {
              ContactData:             {
                FirstName:     args[:firstname].to_s,
                LastName:      args[:lastname].to_s,
                StreetAddress: [args[:address_01].to_s, args.dig(:address_02).to_s].compact_blank.join(', '),
                City:          args[:city].to_s,
                State:         args[:state].to_s,
                PostalCode:    args[:postal_code].to_s,
                Email:         args.dig(:email).to_s,
                PhoneNumber:   args.dig(:phone_number).to_s,
                Tags:          args.dig(:tag_names)
              },
              NumberOfNeighborsToMail: (args.dig(:neighbor_count) || 20).to_i
            }
            target_url = 'neighbormailing'
          else
            @message = 'Contact First Name, Last Name, Address, City, State & Postal Code are required.'
            return @result
          end

          body[:QuickSendID]             = args[:quick_send_id].to_i
          body[:SameStreetOnly]          = args.dig(:same_street_only).to_bool

          sendjim_request(
            body:,
            error_message_prepend: 'Integrations::SendJim::NeighborQuickSend',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/#{target_url}"
          )

          if @success && @result.dig(:Code).to_i.zero?
            @result = true
          else
            @result  = false
            @success = false
          end

          @result
        end

        # POST/PUT contact to SendJim
        # sj_client.push_contact()
        # general data
        # (req) firstname:     (String)
        # (req) lastname:      (String)
        # (req) address_01:    (String)
        # (opt) address_02:    (String)
        # (req) city:          (String)
        # (opt) email:         (String)
        # (req) state:         (String)
        # (opt) phone_number:  (String)
        # (req) postal_code:   (String)
        # update an existing SendJim contact data
        # (opt) ext_id:        (Integer)
        # create a new SendJim contact data
        # (opt) tag_names:     (Array)
        def push_contact(args = {})
          reset_attributes
          @result = {}

          contact = {}
          contact[:FirstName]     = args[:firstname].to_s if args.dig(:firstname).present?
          contact[:LastName]      = args[:lastname].to_s if args.dig(:lastname).present?
          contact[:StreetAddress] = [args[:address_01].to_s, args.dig(:address_02).to_s].compact_blank.join(', ') if args.dig(:address_01).present?
          contact[:City]          = args[:city].to_s if args.dig(:city).present?
          contact[:State]         = args[:state].to_s if args.dig(:state).present?
          contact[:PostalCode]    = args[:postal_code].to_s if args.dig(:postal_code).present?
          contact[:Email]         = args[:email].to_s if args.dig(:email).present?
          contact[:PhoneNumber]   = args[:phone_number].to_s if args.dig(:phone_number).present?

          if args.dig(:ext_id).to_i.positive?
            @result = sendjim_request(
              body:                  contact,
              error_message_prepend: 'Integrations::SendJim::PushContact',
              method:                'put',
              params:                nil,
              default_result:        @result,
              url:                   "#{base_url}/#{api_url}/contact/#{args[:ext_id]}"
            )

            if @success && @result.dig(:Contact).present?
              @result = @result[:Contact].dig(:ContactID)&.to_i
            else
              @result  = 0
              @success = false
            end
          elsif args.dig(:address_01).to_s.present? && args.dig(:city).to_s.present? && args.dig(:state).to_s.present? && args.dig(:postal_code).to_s.present?
            contact[:Tags] = args[:tag_names] if args.dig(:tag_names)

            @result = sendjim_request(
              body:                  { Contacts: [contact] },
              error_message_prepend: 'Integrations::SendJim::PushContact',
              method:                'post',
              params:                nil,
              default_result:        @result,
              url:                   "#{base_url}/#{api_url}/contact"
            )

            if @success && @result.dig(:ContactsSaved).present?
              @result = @result[:ContactsSaved].first.dig(:ContactID)&.to_i
            else
              @result  = 0
              @success = false
            end
          else
            @result = 0
          end

          @result
        end

        # POST a Quick Send Mailing by Contact or SendJim Contact ID
        # sj_client.quick_send()
        # general data
        # (req) quick_send_id: (Integer)
        # posting by Contact data
        # (req) firstname:     (String)
        # (req) lastname:      (String)
        # (req) address_01:    (String)
        # (opt) address_02:    (String)
        # (req) city:          (String)
        # (opt) email:         (String)
        # (req) state:         (String)
        # (opt) phone_number:  (String)
        # (req) postal_code:   (String)
        # (opt) tag_names:     (Array)
        # posting by SendJim Contact ID data
        # (req) ext_id:        (Integer)
        def quick_send(args = {})
          reset_attributes
          @result = {}

          if args.dig(:quick_send_id).to_i.zero?
            @message = 'SendJim Quick Send ID is required.'
            return @result
          end

          if args.dig(:ext_id).to_i.positive?
            body = {
              ContactID:   args[:ext_id].to_i,
              QuickSendID: args[:quick_send_id].to_i
            }
          elsif args.dig(:firstname).to_s.present? && args.dig(:lastname).to_s.present? && args.dig(:address_01).to_s.present? && args.dig(:city).to_s.present? && args.dig(:state).to_s.present? && args.dig(:postal_code).to_s.present?
            body = {
              ContactData: {
                FirstName:     args[:firstname].to_s,
                LastName:      args[:lastname].to_s,
                StreetAddress: [args[:address_01].to_s, args.dig(:address_02).to_s].compact_blank.join(', '),
                City:          args[:city].to_s,
                State:         args[:state].to_s,
                PostalCode:    args[:postal_code].to_s,
                Email:         args.dig(:email).to_s,
                PhoneNumber:   args.dig(:phone_number).to_s,
                Tags:          args.dig(:tag_names)
              },
              QuickSendID: args[:quick_send_id].to_i
            }
          else
            @message = 'Contact First Name, Last Name, Address, City, State & Postal Code are required.'
            return @result
          end

          sendjim_request(
            body:,
            error_message_prepend: 'Integrations::SendJim::QuickSend',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/contact-quicksend"
          )

          if @success && @result.dig(:Code).to_i.zero?
            @result = true
          else
            @result  = false
            @success = false
          end

          @result
        end

        # GET all Quick Sends
        # sj_client.quick_sends
        def quick_sends
          reset_attributes
          @result = {}

          @result = sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::QuickSends',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/quicksends"
          )&.dig(:QuickSends) || []
        end

        # GET the number of neighbors within a radius of an address
        # sj_client.radius_neighbors()
        # (req) address_01:      (String)
        # (opt) address_02:      (String)
        # (req) city:            (String)
        # (req) state:           (String)
        # (req) postal_code:     (String)
        # (req) radius:          (float)
        def radius_neighbors(args = {})
          reset_attributes
          @result = 0

          if args.dig(:radius).to_f.zero?
            @message = 'Radius is required.'
            return @result
          elsif args.dig(:address_01).to_s.blank? || args.dig(:city).to_s.blank? || args.dig(:state).to_s.blank? || args.dig(:postal_code).to_s.blank?
            @message = 'Contact Address, City, State & Postal Code are required.'
            return @result
          end

          params = {
            streetAddress:  [args[:address_01].to_s, args.dig(:address_02).to_s].compact_blank.join(', '),
            city:           args[:city].to_s,
            state:          args[:state].to_s,
            postalCode:     args[:postal_code].to_s,
            radiusInMeters: self.miles_to_meters(args[:radius].to_f)
          }

          @result = sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::RadiusNeighbors',
            method:                'get',
            params:,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/neighbors-of-address-by-radius"
          )&.dig(:TotalAddresses).to_i
        end

        # POST to SendJim API to request token
        # sj_client.request_token(String)
        # (req) short_lived_token: (String)
        def request_token(short_lived_token)
          reset_attributes
          @result = {}

          body = {
            ClientKey:    Rails.application.credentials[:sendjim][:chiirp][:client_key],
            ClientSecret: Rails.application.credentials[:sendjim][:chiirp][:client_secret],
            RequestToken: short_lived_token
          }

          @result = sendjim_request(
            body:,
            error_message_prepend: 'Integrations::SendJim::RequestToken',
            method:                'post',
            params:                nil,
            default_result:        @result,
            url:                   'https://members.sendjim.com/OAuth/Grant'
          )

          if @result.dig(:GrantToken).to_s.present?
            @result = @result[:GrantToken].to_s
          else
            @message = @message.presence || 'Token was not received.'
            @result  = ''
            @success = false
          end

          @result
        end

        def success?
          @success
        end

        # GET Quick User
        # sj_client.user
        def user
          reset_attributes
          @result = {}

          sendjim_request(
            body:                  nil,
            error_message_prepend: 'Integrations::SendJim::User',
            method:                'get',
            params:                nil,
            default_result:        @result,
            url:                   "#{base_url}/#{api_url}/user"
          )
        end

        private

        def api_url
          'api'
        end

        def base_url
          'https://api.sendjim.com'
        end

        def miles_to_meters(miles)
          (miles * 1609.34).to_i
        end

        def record_api_call(error_message_prepend)
          Clients::ApiCall.create(target: 'sendjim', client_api_id: @token, api_call: error_message_prepend)
        end

        def reset_attributes
          @error          = 0
          @faraday_result = nil
          @message        = ''
          @success        = false
        end

        # sendjim_request(
        #   body:                  Hash,
        #   error_message_prepend: 'Integrations::SendJim.xxx',
        #   method:                String,
        #   params:                Hash,
        #   default_result:        @result,
        #   url:                   String
        # )
        def sendjim_request(args = {})
          reset_attributes
          body                  = args.dig(:body)
          error_message_prepend = args.dig(:error_message_prepend) || 'Integrations::SendJim::SendjimRequest'
          faraday_method        = (args.dig(:method) || 'get').to_s
          params                = args.dig(:params)
          @result               = args.dig(:default_result)
          url                   = args.dig(:url).to_s

          if url.blank?
            @message = 'SendJim API URL is required.'
            return @result
          end

          # loop do
          #   redos ||= 0

          record_api_call(error_message_prepend)

          @success, @error, @message = Retryable.with_retries(
            rescue_class:          [Faraday::TimeoutError, Faraday::ConnectionFailed],
            error_message_prepend:,
            current_variables:     {
              parent_body:                  args.dig(:body),
              parent_error_message_prepend: args.dig(:error_message_prepend),
              parent_method:                args.dig(:method),
              parent_params:                args.dig(:params),
              parent_result:                args.dig(:default_result),
              parent_url:                   args.dig(:url),
              parent_file:                  __FILE__,
              parent_line:                  __LINE__
            }
          ) do
            @faraday_result = Faraday.send(faraday_method, url) do |req|
              req.headers['Authorization'] = "Token #{@token}"
              req.headers['Content-Type']  = 'application/json'
              req.headers['API_VERSION']   = '3'
              req.params                   = params if params.present?
              req.body                     = body.to_json if body.present?
            end
          end

          case @faraday_result&.status
          when 200
            result   = JSON.parse(@faraday_result.body)
            @result  = if result.respond_to?(:deep_symbolize_keys)
                         result.deep_symbolize_keys
                       elsif result.respond_to?(:map)
                         result.map(&:deep_symbolize_keys)
                       else
                         result
                       end

            if @result.is_a?(Hash)

              case @result.dig(:Code).to_i
              when 404, 405, 411, 412, 500
                @message = @result.dig(:Message).to_s
                @result  = args.dig(:default_result)
                @success = false
              end
            end
          when 401
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = args.dig(:default_result)
            @success = false
          else
            @error   = @faraday_result&.status
            @message = @faraday_result&.reason_phrase
            @result  = args.dig(:default_result)
            @success = false

            ProcessError::Report.send(
              error_message: "#{error_message_prepend}: #{@faraday_result&.reason_phrase} (#{@faraday_result&.status}): #{@faraday_result&.body}",
              variables:     {
                args:                   args.inspect,
                faraday_result:         @faraday_result&.inspect,
                faraday_result_methods: @faraday_result&.methods.inspect,
                reason_phrase:          @faraday_result&.reason_phrase.inspect,
                result:                 @result.inspect,
                status:                 @faraday_result&.status.inspect
              },
              file:          __FILE__,
              line:          __LINE__
            )
          end

          #   break
          # end

          # JsonLog.info error_message_prepend, { success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }
          Rails.logger.info "#{error_message_prepend}: #{{ success: @success, message: @message, error: @error, result: @result, faraday_result: @faraday_result }.to_json} - File: #{__FILE__} - Line: #{__LINE__}"

          @result
        end
      end
    end
  end
end
