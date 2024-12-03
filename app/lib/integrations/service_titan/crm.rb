# frozen_string_literal: true

# app/lib/integrations/service_titan/crm.rb
module Integrations
  module ServiceTitan
    module Crm
      # parse Contact data from ServiceTitan CustomerModel
      # st_client.parse_customer()
      #   (req) st_customer_model:    (Hash / ServiceTitan Customer Model)
      def parse_customer(st_customer_model:)
        reset_attributes
        @result = {
          contact:         {},
          phones:          {},
          customer_id:     0,
          customer_type:   '',
          account_balance: 0
        }

        if st_customer_model.dig(:id).to_i.zero? && st_customer_model.dig(:contacts).blank?
          @message = 'ServiceTitan Customer data is required.'
          return @result
        end

        (st_customer_model.dig(:contacts) || {}).each do |customer_contact|
          if customer_contact.dig(:type).to_s.present? && customer_contact.dig(:value).to_s.present?
            phone = customer_contact[:value].to_s.clean_phone

            case customer_contact[:type].to_s.downcase
            when 'phone'

              if customer_contact.dig(:memo).to_s.downcase.include?('cell')
                @result[:phones][phone] = 'mobile'

                if (phone_settings = (st_customer_model.dig(:phoneSettings) || {}).find { |phone_hash| phone_hash.dig(:phoneNumber) == phone }) && phone_settings.dig(:doNotText).to_bool
                  @result[:contact][:ok2text] = 0
                end
              else
                @result[:phones][phone] = 'other' unless @result[:phones].dig(phone)
              end
            when 'mobilephone'
              @result[:phones][phone] = 'mobile'

              if (phone_settings = (st_customer_model.dig(:phoneSettings) || {}).find { |phone_hash| phone_hash.dig(:phoneNumber) == phone }) && phone_settings.dig(:doNotText).to_bool
                @result[:contact][:ok2text] = 0
              end
            when 'fax'
              @result[:phones][phone] = 'fax'
            when 'email'
              @result[:contact][:email] = customer_contact[:value].to_s
            end
          end
        end

        @result[:customer_id]             = st_customer_model.dig(:id).to_i
        @result[:customer_type]           = st_customer_model.dig(:type).to_s.downcase
        @result[:account_balance]         = st_customer_model.dig(:balance).to_d

        contact_name                      = st_customer_model.dig(:name).to_s.dup.parse_name
        @result[:contact][:lastname]      = contact_name[:lastname]
        @result[:contact][:firstname]     = contact_name[:firstname].presence || 'Friend'
        @result[:contact][:email]         = st_customer_model.dig(:email).to_s if st_customer_model.dig(:email).to_s.present?
        @result[:contact][:ok2email]      = st_customer_model.dig(:doNotMail).to_bool ? 0 : 1
        @result[:contact][:ext_ref_id]    = st_customer_model.dig(:id).to_i
        @result[:contact][:address1]      = st_customer_model.dig(:address, :street).to_s
        @result[:contact][:city]          = st_customer_model.dig(:address, :city).to_s
        @result[:contact][:state]         = st_customer_model.dig(:address, :state).to_s
        @result[:contact][:zipcode]       = st_customer_model.dig(:address, :zip).to_s
        @result[:contact][:ok2text]       = 0 if st_customer_model.dig(:phoneSettings)&.map { |ps| ps.dig(:doNotText) }&.include?(true)

        @success = true

        @result
      end
      # example ServiceTitan customer model (as received by API call)
      # {
      #   :id=>204421041,
      #   :active=>true,
      #   :name=>"Ashly Escobar ",
      #   :type=>"Residential",
      #   :address=>{
      #     :street=>"1038 Vanston Way",
      #     :unit=>nil,
      #     :city=>"Roseville",
      #     :state=>"CA",
      #     :zip=>"95747",
      #     :country=>"USA",
      #     :latitude=>38.75369209999999,
      #     :longitude=>-121.3374854
      #   },
      #   :customFields=>[],
      #   :balance=>0.0,
      #   :tagTypeIds=>[],
      #   :doNotMail=>false,
      #   :doNotService=>false,
      #   :createdOn=>"2023-03-12T23:12:27.753398Z",
      #   :createdById=>152441865,
      #   :modifiedOn=>"2023-03-12T23:12:27.7622606Z",
      #   :mergedToId=>nil,
      #   :externalData=>nil
      # }
      # example ServiceTitan customer model (as received by webhook)
      # {
      #   id:                  2829263,
      #   name:                'Renee Waite',
      #   type:                'Residential',
      #   email:               'waite.renee@yahoo.com',
      #   active:              true,
      #   address:             {
      #     zip:           '95334',
      #     city:          'Livingston',
      #     unit:          null,
      #     state:         'CA',
      #     street:        '310 Dosangh Ct',
      #     country:       'USA',
      #     streetAddress: '310 Dosangh Ct'
      #   },
      #   balance:             nil,
      #   contacts:            [
      #     {
      #       id:         2837190,
      #       memo:       null,
      #       type:       'MobilePhone',
      #       value:      '2098500045',
      #       active:     true,
      #       modifiedOn: '2021-11-30T23:47:47.9417671'
      #     },
      #     {
      #       id:         2837191,
      #       memo:       null,
      #       type:       'Email',
      #       value:      'waite.renee@yahoo.com',
      #       active:     true,
      #       modifiedOn: '2021-04-06T17:49:26.6133333'
      #     }
      #   ],
      #   importId:            '29716825',
      #   createdBy:           null,
      #   createdOn:           '2021-04-06T17:49:20.77',
      #   doNotMail:           false,
      #   modifiedOn:          '2022-06-03T17:56:23.3165544',
      #   memberships:         [
      #     {
      #       id:         20662050,
      #       to:         '2023-06-02T00:00:00',
      #       from:       '2022-06-03T00:00:00',
      #       type:       {
      #         id:     15374245,
      #         name:   'Comfort Club',
      #         active: true
      #       },
      #       active:     true,
      #       status:     'Active',
      #       locationId: 2831123
      #     }
      #   ],
      #   customFields:        [],
      #   doNotService:        false,
      #   phoneSettings:       [
      #     {
      #       doNotText:   false,
      #       phoneNumber: '2098500045'
      #     }
      #   ],
      #   hasActiveMembership: true
      # }

      # parse location data from ServiceTitan LocationModel
      # st_client.parse_location()
      #   (req) st_location_model: (Hash / ServiceTitan Location Model)
      def parse_location(st_location_model)
        reset_attributes
        @result = {}

        if st_location_model.dig(:id).to_i.zero?
          @message = 'ServiceTitan Location data is required.'
          return @result
        end

        @result = {
          id:          st_location_model.dig(:id).to_i,
          active:      st_location_model.dig(:active).to_bool,
          name:        st_location_model.dig(:name).to_s,
          email:       st_location_model.dig(:email).to_s,
          job_address: {
            address: st_location_model.dig(:address, :street).to_s,
            city:    st_location_model.dig(:address, :city).to_s,
            state:   st_location_model.dig(:address, :state).to_s,
            zipcode: st_location_model.dig(:address, :zip).to_s
          },
          contacts:    []
        }

        (st_location_model.dig(:contacts) || []).flatten.each do |contact|
          @result[:contacts] << {
            id:     contact.dig(:id).to_i,
            type:   contact.dig(:type).to_s,
            value:  contact.dig(:value).to_s,
            active: contact.dig(:active).to_bool
          }
        end

        @success = true

        @result
      end
    end
  end
end
