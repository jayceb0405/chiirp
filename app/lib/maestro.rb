# frozen_string_literal: true

# app/lib/maestro.rb
class Maestro
  # process various API calls to Maestro

  # conversion from Maestro time to UTC
  # ActiveSupport::TimeZone["UTC"].parse(reservation_data["ArrivalDate"].to_s)
  # conversion from UTC to Client time zone
  # ActiveSupport::TimeZone[@contact_api_integration.contact.client.time_zone].parse(@contact_api_integration.arrival_date)
  # conversion from UTC to Client time zone formatted for flatpickr
  # ActiveSupport::TimeZone[@contact_api_integration.contact.client.time_zone].parse(@contact_api_integration.arrival_date).strftime("%m/%d/%Y %I:%M %p")
  # conversion from flatpickr to UTC
  # ActiveSupport::TimeZone[@contact_api_integration.contact.client.time_zone].strptime(x, "%m/%d/%Y %I:%M %p").utc.strftime("%FT%TZ")

  def password_hash_create(params)
    # generate sha256 password hash
    #
    # Example:
    # 	maestro_password( api_pass: String, salt: String )
    #
    # Required Parameters:
    # 	api_pass: (String)
    # 	salt:     (String)
    #
    # Optional Parameters:
    #   none
    #
    api_pass = params.include?(:api_pass) ? params[:api_pass].to_s : ''
    salt     = params.include?(:salt) ? params[:salt].to_s : ''

    Digest::SHA2.hexdigest(api_pass + salt)
  end

  def password_hash_validate(params)
    # validate a sha256 password hash
    #
    # Example:
    # 	password_hash_validate( hotel_id: String, password_hash: String )
    #
    # Required Parameters:
    # 	hotel_id:      (String)
    # 	password_hash: (String)
    #
    # Optional Parameters:
    #   none
    #
    hotel_id      = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''
    password_hash = params.include?(:password_hash) ? params[:password_hash].to_s : ''
    response      = nil

    if hotel_id.present? && password_hash.present?
      client_api_integration = ClientApiIntegration.find_by(target: 'maestro', api_key: hotel_id)

      client_api_integration&.salt_responses&.each do |salt, issued|
        if issued < 24.hours.ago
          client_api_integration.salt_responses.delete(salt)
          client_api_integration.save
        elsif password_hash_create(api_pass: client_api_integration.api_pass, salt:) == password_hash
          response = client_api_integration
        end

        break if response
      end
    end

    response
  end

  def process_checkin(params)
    # process received checkins
    #
    # Example:
    # 	process_checkin( client_api_integration: ClientApiIntegration, data: Array, hotel_id: String, password_hash: String )
    #
    # Required Parameters:
    # 	data:                   (Array)
    # 	hotel_id:               (String)
    # 	password_hash:          (String)
    # 	client_api_integration: (ClientApiIntegration)
    #
    # Optional Parameters:
    #   none
    #
    client_api_integration = params.include?(:client_api_integration) && params[:client_api_integration].is_a?(ClientApiIntegration) ? params[:client_api_integration] : nil
    hotel_id               = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''
    password_hash          = params.include?(:password_hash) ? params[:password_hash].to_s : ''
    data                   = params.include?(:data) ? params[:data] : []
    data                   = Array(data)
    response               = {
      'Version'      => '1.0',
      'HotelId'      => hotel_id,
      'PasswordHash' => password_hash,
      'Status'       => 'failure',
      'Message'      => 'unexpected data received'
    }

    if client_api_integration

      data.each do |guest_info|
        contact = client_api_integration.client.contacts.joins(:contact_api_integrations).where("contact_api_integrations.data->>'client_code' = '#{guest_info['ClientCode']}'").first

        unless contact
          contact_phone = guest_info['Cell'].to_s.clean_phone(client_api_integration.client.primary_area_code)
          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones: { contact_phone => 'mobile' }, emails: [guest_info['EmailAddress'].to_s]) if contact_phone.length == 10
        end

        if contact
          contact.lastname  = guest_info['LastName'].to_s
          contact.firstname = guest_info['FirstName'].to_s
          contact.email     = guest_info['EmailAddress'].to_s
          contact.ok2email  = guest_info['EmailOptOut'].to_s.casecmp?('false') ? 0 : 1

          if contact.save
            contact_api_integration = contact.contact_api_integrations.find_or_initialize_by(target: 'maestro')

            if contact_api_integration
              contact_api_integration.client_code    = guest_info['ClientCode'].to_s
              contact_api_integration.arrival_date   = ActiveSupport::TimeZone['UTC'].parse(guest_info['ArrivalDate'].to_s)
              contact_api_integration.departure_date = ActiveSupport::TimeZone['UTC'].parse(guest_info['DepartureDate'].to_s)
              contact_api_integration.checked_in     = 1
              contact_api_integration.status         = 'checked_in'
              contact_api_integration.room_number    = guest_info['RoomCode'].to_s
              contact_api_integration.save

              # update Custom Fields
              update_contact_custom_fields(client_api_integration:, contact_api_integration:)
            end

            campaign_id       = client_api_integration.checkin_contact_actions.include?('campaign_id') ? client_api_integration.checkin_contact_actions['campaign_id'].to_i : 0
            group_id          = client_api_integration.checkin_contact_actions.include?('group_id') ? client_api_integration.checkin_contact_actions['group_id'].to_i : 0
            stage_id          = client_api_integration.checkin_contact_actions.include?('stage_id') ? client_api_integration.checkin_contact_actions['stage_id'].to_i : 0
            tag_id            = client_api_integration.checkin_contact_actions.include?('tag_id') ? client_api_integration.checkin_contact_actions['tag_id'].to_i : 0
            stop_campaign_ids = client_api_integration.checkin_contact_actions['stop_campaign_ids']

            contact.process_actions(
              campaign_id:,
              group_id:,
              stage_id:,
              tag_id:,
              stop_campaign_ids:
            )
          end
        end
      end

      response['Status']  = 'success'
      response['Message'] = ''
    end

    response
  end
  # <?xml version=”1.0” encoding=”utf-8”?>
  # <Request>
  # 	<Version>1.0</Version>
  # 	<HotelId>0005a</HotelId>
  # 	<PasswordHash>0102030405060708090a0b0c0d0e0f</PasswordHash>
  # 	<Action>CheckIn</Action>
  # 	<CheckInData>
  # 		<GuestInfo>
  # 			<GuestName>Decker, Eric</GuestName>
  # 			<LastName>Decker</LastName>
  # 			<FirstName>Eric</FirstName>
  # 			<Salutation>Mr.</Salutation>
  # 			<ZipCode>90210</ZipCode>
  # 			<Country>US</Country>
  # 			<EmailAddress>ericd@gmail.com</EmailAddress>
  # 			<Cell>201-333-2323</Cell>
  # 			<Language>en</Language>
  # 			<Vip>v</Vip>
  # 			<AccountNumber>d2134511</AccountNumber>
  # 			<EmailOptOut>false</EmailOptOut>
  # 			<RegularMailOptOut>false</RegularMailOptOut>
  # 			<DateOfBirth>1972-11-03</DateOfBirth>
  # 			<ReservationNumber>321321</ReservationNumber>
  # 			<ReservationNumberKey>321321-1</ReservationNumberKey>
  # 			<ArrivalDate>2014-09-20T15:30:00-5:00</ArrivalDate>
  # 			<DepartureDate>2014-09-27T11:00:00-5:00</DepartureDate>
  # 			<BookingDate>2014-03-08T10:21:00-5:00</BookingDate>
  # 			<ReservationLastModifyDate>2014-07-12T09:01:00-5:00</ReservationLastModifyDate>
  # 			<Adults>3</Adults>
  # 			<Children>1</Children>
  # 			<BuildingCode>bld</BuildingCode>
  # 			<RoomCode>0201</RoomCode>
  # 			<RoomTypeCode>king</RoomTypeCode>
  # 			<RoomTypeDescription>king bed, city view</RoomTypeDescription>
  # 			<GuestSelection>1</GuestSelection>
  # 			<FolioNumber>56432</FolioNumber>
  # 			<CreditAvailable>300.00</CreditAvailable>
  # 			<PostRestrictions>0</PostRestrictions>
  # 			<TelephoneRestrictions>0</TelephoneRestrictions>
  # 			<GroupTypeCode>conf</GroupTypeCode>
  # 			<Source>nytimes</Source>
  # 			<SubSource>fallpromo</SubSource>
  # 			<ComplimentaryUse>false</ComplimentaryUse>
  # 			<HouseUse>false</HouseUse>
  # 			<MealPlan>mpa</MealPlan>
  # 			<RateType>unlimited</RateType>
  # 			<TotalRateAmount>3245.69</TotalRateAmount>
  # 			<TotalRateAmountTaxes>259.66</TotalRateAmountTaxes>
  # 			<RoomRateAmount>1022.00</RoomRateAmount>
  # 			<RoomRateAmountTaxes>81.90</RoomRateAmountTaxes>
  # 			<ResortFee>69.93</ResortFee>
  # 			<ResortFeeTaxes>5.59</ResortFeeTaxes>
  # 			<HousekeepingFee>0.00</HousekeepingFee>
  # 			<HousekeepingFeeTaxes>0.00</HousekeepingFeeTaxes>
  # 			<SpaFee>125.00</SpaFee>
  # 			<SpaFeeTaxes>10.00</SpaFeeTaxes>
  # 			<FirstRoomNightAmount>146.00</FirstRoomNightAmount>
  # 			<ReservationText>
  # 				<Text>Guest has indicated that they are arriving early and they</Text>
  # 				<Text>would like us to do what we can to have a room ready for</Text>
  # 				<Text>them if at all possible.</Text>
  # 			</ReservationText>
  # 			<SharerInfo>
  # 				<SharerReservationNumber>321123</SharerReservationNumber>
  # 			</SharerInfo>
  # 			<Group>
  # 				<GroupReservation>12345677</GroupReservation>
  # 				<Name>Millers Ski Group</Name>
  # 			</Group>
  # 		</GuestInfo>
  # 	</CheckInData>
  # </Request>

  def process_checkout(params)
    # process received checkouts
    #
    # Example:
    # 	process_checkout( client_api_integration: ClientApiIntegration, data: Array, hotel_id: String, password_hash: String )
    #
    # Required Parameters:
    # 	data:                   (Array)
    # 	hotel_id:               (String)
    # 	password_hash:          (String)
    # 	client_api_integration: (ClientApiIntegration)
    #
    # Optional Parameters:
    #   none
    #
    client_api_integration = params.include?(:client_api_integration) && params[:client_api_integration].is_a?(ClientApiIntegration) ? params[:client_api_integration] : nil
    hotel_id               = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''
    password_hash          = params.include?(:password_hash) ? params[:password_hash].to_s : ''
    data                   = params.include?(:data) ? params[:data] : []
    data                   = Array(data)
    response               = {
      'Version'      => '1.0',
      'HotelId'      => hotel_id,
      'PasswordHash' => password_hash,
      'Status'       => 'failure',
      'Message'      => 'unexpected data received'
    }

    if client_api_integration

      data.each do |guest_info|
        contact = client_api_integration.client.contacts.joins(:contact_api_integrations).where("contact_api_integrations.data->>'client_code' = '#{guest_info['ClientCode']}'").first

        unless contact
          contact_phone = guest_info['Cell'].to_s.clean_phone(client_api_integration.client.primary_area_code)
          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones: { contact_phone => 'mobile' }, emails: [guest_info['EmailAddress'].to_s]) if contact_phone.length == 10
        end

        if contact
          contact.lastname  = guest_info['LastName'].to_s
          contact.firstname = guest_info['FirstName'].to_s
          contact.email     = guest_info['EmailAddress'].to_s
          contact.ok2email  = guest_info['EmailOptOut'].to_s.casecmp?('false') ? 0 : 1

          if contact.save
            contact_api_integration = contact.contact_api_integrations.find_or_initialize_by(target: 'maestro')

            if contact_api_integration
              contact_api_integration.client_code    = guest_info['ClientCode'].to_s
              contact_api_integration.arrival_date   = ActiveSupport::TimeZone['UTC'].parse(guest_info['ArrivalDate'].to_s)
              contact_api_integration.departure_date = ActiveSupport::TimeZone['UTC'].parse(guest_info['DepartureDate'].to_s)
              contact_api_integration.checked_in     = 0
              contact_api_integration.status         = 'checked_out'
              contact_api_integration.room_number    = guest_info['RoomCode'].to_s
              contact_api_integration.save

              # update Custom Fields
              update_contact_custom_fields(client_api_integration:, contact_api_integration:)
            end

            campaign_id       = client_api_integration.checkout_contact_actions.include?('campaign_id') ? client_api_integration.checkout_contact_actions['campaign_id'].to_i : 0
            group_id          = client_api_integration.checkout_contact_actions.include?('group_id') ? client_api_integration.checkout_contact_actions['group_id'].to_i : 0
            stage_id          = client_api_integration.checkout_contact_actions.include?('stage_id') ? client_api_integration.checkout_contact_actions['stage_id'].to_i : 0
            tag_id            = client_api_integration.checkout_contact_actions.include?('tag_id') ? client_api_integration.checkout_contact_actions['tag_id'].to_i : 0
            stop_campaign_ids = client_api_integration.checkout_contact_actions['stop_campaign_ids']

            contact.process_actions(
              campaign_id:,
              group_id:,
              stage_id:,
              tag_id:,
              stop_campaign_ids:
            )
          end
        end
      end

      response['Status']  = 'success'
      response['Message'] = ''
    end

    response
  end
  # <?xml version=”1.0” encoding=”utf-8”?>
  # <Request>
  # 	<Version>1.0</Version>
  # 	<HotelId>0005a</HotelId>
  # 	<PasswordHash>0399f5476a7334b532145</PasswordHash>
  # 	<Action>CheckOut</Action>
  # 	<CheckOutData>
  # 		<GuestInfo>
  # 			<GuestName>Decker, Eric</GuestName>
  # 			<LastName>Decker</LastName>
  # 			<FirstName>Eric</FirstName>
  # 			<Salutation>Mr.</Salutation>
  # 			<ZipCode>90210</ZipCode>
  # 			<Country>US</Country>
  # 			<EmailAddress>ericd@gmail.com</EmailAddress>
  # 			<Cell>201-333-2323</Cell>
  # 			<GuestCellNumber>201-333-2323</GuestCellNumber>
  # 			<Language>en</Language>
  # 			<Vip>v</Vip>
  # 			<AccountNumber>d2134511</AccountNumber>
  # 			<EmailOptOut>false</EmailOptOut>
  # 			<RegularMailOptOut>false</RegularMailOptOut>
  # 			<DateOfBirth>1972-11-03</DateOfBirth>
  # 			<ReservationNumber>123456678</ReservationNumber>
  # 			<ReservationNumberKey>123456678-1</ReservationNumberKey>
  # 			<ArrivalDate>2014-09-20T15:30:00-5:00</ArrivalDate>
  # 			<DepartureDate>2014-09-27T11:00:00-5:00</DepartureDate>
  # 			<BookingDate>2014-04-31T06:50:00-5:00</BookingDate>
  # 			<ReservationLastModifyDate>2014-07-19T10:13:00-5:00</ReservationLastModifyDate>
  # 			<BuildingCode>bld</BuildingCode>
  # 			<RoomCode>0201</RoomCode>
  # 			<RoomTypeCode>king</RoomTypeCode>
  # 			<RoomTypeDescription>king bed, city view</RoomTypeDescription>
  # 			<SharerInfo>
  # 				<SharerReservationNumber>321123</SharerReservationNumber>
  # 			</SharerInfo>
  # 			<Group>
  # 				<GroupReservation>12345677</GroupReservation>
  # 				<Name>Millers Ski Group</Name>
  # 			</Group>
  # 		</GuestInfo>
  # 	</CheckOutData>
  # </Request>

  def process_housekeeping_status(params)
    # process received housekeeping status
    #
    # Example:
    # 	process_housekeeping_status( client_api_integration: ClientApiIntegration, data: Array, hotel_id: String, password_hash: String )
    #
    # Required Parameters:
    # 	data:                   (Array)
    # 	hotel_id:               (String)
    # 	password_hash:          (String)
    # 	client_api_integration: (ClientApiIntegration)
    #
    # Optional Parameters:
    #   none
    #
    client_api_integration = params.include?(:client_api_integration) && params[:client_api_integration].is_a?(ClientApiIntegration) ? params[:client_api_integration] : nil
    hotel_id               = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''
    password_hash          = params.include?(:password_hash) ? params[:password_hash].to_s : ''
    data                   = params.include?(:data) ? params[:data] : []
    data                   = Array(data)
    response               = {
      'Version'      => '1.0',
      'HotelId'      => hotel_id,
      'PasswordHash' => password_hash,
      'Status'       => 'failure',
      'Message'      => 'unexpected data received'
    }

    if client_api_integration

      data.each do |rooms|
        # no data to collect here
      end

      response['Status']  = 'success'
      response['Message'] = ''
    end

    response
  end
  # <?xml version=”1.0” encoding=”utf-8”?>
  # <Request>
  # 	<Version>1.0</Version>
  # 	<HotelId>0005a</HotelId>
  # 	<PasswordHash>0102030405060708090a0b0c0d0e0f</PasswordHash>
  # 	<Action>HousekeepingStatus</Action>
  # 	<Rooms>
  # 		<HousekeepingData>
  # 			<BuildingCode>bld</BuildingCode>
  # 			<RoomCode>0202</RoomCode>
  # 			<RoomTypeCode>king</RoomTypeCode>
  # 			<RoomType>king</RoomType>
  # 			<RoomStatus>occupied</RoomStatus>
  # 			<HousekeepingStatus>oc</HousekeepingStatus>
  # 			<HousekeepingStatusDescription>occupied clean</HousekeepingStatusDescription>
  # 			<SoftCheckInData>
  # 				<ReservationNumber>12345678</ReservationNumber>
  # 				<ReservationNumberKey>12345678-1</ReservationNumberKey>
  # 				<LastName>Smith</LastName>
  # 				<ClientCode>1234444</ClientCode>
  # 				<Email>johnesmith@gmail.com</Email>
  # 				<Cell>201-333-2323</Cell>
  # 				<GuestNotifiedEmail>false</GuestNotifiedEmail>
  # 				<GuestNotifiedSMS>true</GuestNotifiedSMS>
  # 			</SoftCheckInData>
  # 		</HousekeepingData>
  # 		<HousekeepingData>
  # 			<BuildingCode>bld</BuildingCode>
  # 			<RoomCode>0213</RoomCode>
  # 			<RoomType>sgl</RoomType>
  # 			<RoomStatus>empty</RoomStatus>
  # 			<HousekeepingStatus>vd</HousekeepingStatus>
  # 			<HousekeepingStatusDescription>vacant dirty</HousekeepingStatusDescription>
  # 		</HousekeepingData>
  # 	</Rooms>
  # </Request>

  def process_post(params)
    # process an XML post from Maestro
    #
    # Example:
    # 	Maestro.new.process_post( xml: XML )
    #
    # Required Parameters:
    # 	xml_params: (Hash)
    #
    # Optional Parameters:
    #   none
    #
    response = {
      'Version' => '1.0',
      'Status'  => 'failure',
      'Message' => 'unexpected request'
    }
    xml_params = params.include?(:xml_params) && params[:xml_params].is_a?(Hash) ? params[:xml_params] : ''

    if xml_params.present?
      # XML was received

      if xml_params.include?('GetSalt') && xml_params.include?('HotelId')
        # Maestro requesting salt
        response = salt_request_response(hotel_id: xml_params['HotelId'])
      elsif xml_params.include?('PasswordHash') && xml_params.include?('HotelId')
        response['HotelId']      = xml_params['HotelId']
        response['PasswordHash'] = xml_params['PasswordHash']
        client_api_integration   = password_hash_validate(hotel_id: xml_params['HotelId'], password_hash: xml_params['PasswordHash'])

        if client_api_integration && xml_params.include?('Action') && xml_params['Action'].to_s.present?

          case xml_params['Action'].to_s
          when 'CheckIn'

            if xml_params.include?('CheckInData') && xml_params['CheckInData'].include?('GuestInfo')
              response = process_checkin(
                client_api_integration:,
                data:                   xml_params['CheckInData']['GuestInfo'],
                hotel_id:               xml_params['HotelId'],
                password_hash:          xml_params['PasswordHash']
              )
            end
          when 'CheckOut'

            if xml_params.include?('CheckOutData') && xml_params['CheckOutData'].include?('GuestInfo')
              response = process_checkout(
                client_api_integration:,
                data:                   xml_params['CheckOutData']['GuestInfo'],
                hotel_id:               xml_params['HotelId'],
                password_hash:          xml_params['PasswordHash']
              )
            end
          when 'RoomMove'

            if xml_params.include?('DestinationRoomInformation') && xml_params['DestinationRoomInformation'].include?('GuestInfo')
              response = process_roommove(
                client_api_integration:,
                data:                   xml_params['DestinationRoomInformation']['GuestInfo'],
                hotel_id:               xml_params['HotelId'],
                password_hash:          xml_params['PasswordHash']
              )
            end
          when 'ReservationList'

            if xml_params.include?('Reservations') && xml_params['Reservations'].include?('ReservationData')
              response = process_reservation(
                client_api_integration:,
                data:                   xml_params['Reservations']['ReservationData'],
                hotel_id:               xml_params['HotelId'],
                password_hash:          xml_params['PasswordHash']
              )
            end
          when 'HousekeepingStatus'

            if xml_params.include?('HousekeepingStatus') && xml_params['HousekeepingStatus'].include?('Rooms')
              response = process_housekeeping_status(
                client_api_integration:,
                data:                   xml_params['HousekeepingStatus']['Rooms'],
                hotel_id:               xml_params['HotelId'],
                password_hash:          xml_params['PasswordHash']
              )
            end
          end
        end
      end
    end

    response
  end

  def process_reservation(params)
    # process received reservations
    #
    # Example:
    # 	process_reservation( client_api_integration: ClientApiIntegration, data: Array, hotel_id: String, password_hash: String )
    #
    # Required Parameters:
    # 	data:                   (Array)
    # 	hotel_id:               (String)
    # 	password_hash:          (String)
    # 	client_api_integration: (ClientApiIntegration)
    #
    # Optional Parameters:
    #   none
    #
    client_api_integration = params.include?(:client_api_integration) && params[:client_api_integration].is_a?(ClientApiIntegration) ? params[:client_api_integration] : nil
    hotel_id               = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''
    password_hash          = params.include?(:password_hash) ? params[:password_hash].to_s : ''
    data                   = params.include?(:data) ? params[:data] : []
    data                   = Array(data)
    response               = {
      'Version'      => '1.0',
      'HotelId'      => hotel_id,
      'PasswordHash' => password_hash,
      'Status'       => 'failure',
      'Message'      => 'unexpected data received'
    }

    if client_api_integration

      data.each do |reservation_data|
        contact_phone = (if reservation_data['Cell'].to_s.present?
                           reservation_data['Cell'].to_s
                         else
                           (reservation_data['Phone'].to_s.present? ? reservation_data['Phone'] : '')
                         end).clean_phone(client_api_integration.client.primary_area_code)
        contact_email = reservation_data['EmailAddress'].to_s

        if contact_phone.length == 10
          contact           = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones: { contact_phone => 'mobile' }, emails: [contact_email])
          contact.lastname  = reservation_data['LastName'].to_s
          contact.firstname = reservation_data['FirstName'].to_s
          contact.address1  = reservation_data['Street'].to_s
          contact.address2  = reservation_data['Address2'].to_s
          contact.city      = reservation_data['City'].to_s
          contact.state     = reservation_data['State'].to_s
          contact.zipcode   = reservation_data['ZipCode'].to_s
          contact.email     = reservation_data['EmailAddress'].to_s
          contact.birthdate = Date.parse(reservation_data['DateOfBirth'].to_s) if reservation_data.include?('DateOfBirth')
          contact.ok2email  = 0 if reservation_data['EmailOptOut'].to_s.casecmp?('false')

          if contact.save
            alt_phone = reservation_data['Phone'].to_s.clean_phone(client_api_integration.client.primary_area_code)

            contact.contact_phones.find_or_create_by(phone: alt_phone, label: 'other') if alt_phone.positive?

            contact_api_integration = contact.contact_api_integrations.find_or_initialize_by(target: 'maestro')

            if contact_api_integration
              contact_api_integration.client_code    = reservation_data['ClientCode'].to_s
              contact_api_integration.arrival_date   = ActiveSupport::TimeZone['UTC'].parse(reservation_data['ArrivalDate'].to_s)
              contact_api_integration.departure_date = ActiveSupport::TimeZone['UTC'].parse(reservation_data['DepartureDate'].to_s)
              contact_api_integration.guest_type     = reservation_data['GuestType'].to_s
              contact_api_integration.checked_in     = (reservation_data['ReservationStatus'].to_s == 'checked_in' ? 1 : 0)
              contact_api_integration.status         = reservation_data['ReservationStatus'].to_s
              contact_api_integration.save

              # update Custom Fields
              update_contact_custom_fields(client_api_integration:, contact_api_integration:)
            end

            campaign_id       = client_api_integration.new_contact_actions.include?('campaign_id') ? client_api_integration.new_contact_actions['campaign_id'].to_i : 0
            group_id          = client_api_integration.new_contact_actions.include?('group_id') ? client_api_integration.new_contact_actions['group_id'].to_i : 0
            stage_id          = client_api_integration.new_contact_actions.include?('stage_id') ? client_api_integration.new_contact_actions['stage_id'].to_i : 0
            tag_id            = client_api_integration.new_contact_actions.include?('tag_id') ? client_api_integration.new_contact_actions['tag_id'].to_i : 0
            stop_campaign_ids = client_api_integration.new_contact_actions['stop_campaign_ids']

            contact.process_actions(
              campaign_id:,
              group_id:,
              stage_id:,
              tag_id:,
              stop_campaign_ids:
            )
          end
        end
      end

      response['Status']  = 'success'
      response['Message'] = ''
    end

    response
  end
  # <?xml version=”1.0” encoding=”utf-8”?>
  # <Request>
  # 	<Version>1.0</Version>
  # 	<HotelId>0005a</HotelId>
  # 	<PasswordHash>0102030405060708090a0b0c0d0e0f</PasswordHash>
  # 	<Action>ReservationList</Action>
  # 	<Reservations>
  # 		<ReservationData>
  # 			<GuestName>Smith, John</GuestName>
  # 			<LastName>Smith</LastName>
  # 			<FirstName>John</FirstName>
  # 			<Salutation>Mr.</Salutation>
  # 			<MiddleInitial>E</MiddleInitial>
  # 			<MiddleName>Edward</MiddleName>
  # 			<Street>123 Main Street South</Street>
  # 			<Address2>Suite 500</Address2>
  # 			<City>Toronto</City>
  # 			<State>ON</State>
  # 			<ZipCode>M7T3Y0</ZipCode>
  # 			<Country>CA</Country>
  # 			<Email>johnesmith@gmail.com</Email>
  # 			<EmailAddress>johnesmith@gmail.com</EmailAddress>
  # 			<Cell>201-333-2323</Cell>
  # 			<Language>en</Language>
  # 			<Vip>a</Vip>
  # 			<AccountNumber>d2134511</AccountNumber>
  # 			<Phone>901-333-9876</Phone>
  # 			<Fax>901-333-8754</Fax>
  # 			<Company>Smiths Cartage</Company>
  # 			<ClientCode>1234444</ClientCode>
  # 			<LoyaltyID>98712376521</LoyaltyID>
  # 			<EmailOptOut>false</EmailOptOut>
  # 			<RegularMailOptOut>false</RegularMailOptOut>
  # 			<DateOfBirth>1965-09-06</DateOfBirth>
  # 			<ReservationNumber>12345678</ReservationNumber>
  # 			<ReservationNumberKey>12345678-1</ReservationNumberKey>
  # 			<ArrivalDate>2015-09-27T14:50:00-5:00</ArrivalDate>
  # 			<DepartureDate>2015-09-29T11:30:00-5:00</DepartureDate>
  # 			<BookingDate>2014-01-08T10:21:00-5:00</BookingDate>
  # 			<ReservationLastModifyDate>2014-07-19T10:13:00-5:00</ReservationLastModifyDate>
  # 			<Nights>2</Nights>
  # 			<Status>reserved</Status>
  # 			<ReservationStatus>reserved</ReservationStatus>
  # 			<Adults>2</Adults>
  # 			<Children>0</Children>
  # 			<Room>
  # 				<BuildingCode>bld</BuildingCode>
  # 				<RoomCode>0202</RoomCode>
  # 				<RoomTypeCode>sgl</RoomTypeCode>
  # 				<RoomTypeDescription>king bed, city view</RoomTypeDescription>
  # 			</Room>
  # 			<RoomTypeAlternates>
  # 				<RoomTypeAlternateData>
  # 					<RoomTypeAlternate>dbl</RoomTypeAlternate>
  # 					<RoomTypeAlternateDescription>double queen</RoomTypeAlternateDescription>
  # 					<RoomTypeUpsellFlag>true</RoomTypeUpsellFlag>
  # 					<RoomTypeUpsellCost>55.00</RoomTypeUpsellCost>
  # 				</RoomTypeAlternateData>
  # 				<RoomTypeAlternateData>
  # 					<RoomTypeAlternate>sglhf</RoomTypeAlternate>
  # 					<RoomTypeAlternateDescription>king bed, high floor</RoomTypeAlternateDescription>
  # 					<RoomTypeUpsellFlag>true</RoomTypeUpsellFlag>
  # 					<RoomTypeUpsellCost>95.00</RoomTypeUpsellCost>
  # 				</RoomTypeAlternateData>
  # 			</RoomTypeAlternates>
  # 			<FolioNumber>3219999</FolioNumber>
  # 			<CreditAvailable>5000.00</CreditAvailable>
  # 			<PostRestrictions>0</PostRestrictions>
  # 			<TelephoneRestrictions>0</TelephoneRestrictions>
  # 			<Source>nytimes</Source>
  # 			<SubSource>fallpromo</SubSource>
  # 			<ComplimentaryUse>false</ComplimentaryUse>
  # 			<HouseUse>false</HouseUse>
  # 			<MealPlan>super8</MealPlan>
  # 			<RateType>golf1</RateType>
  # 			<GuestType>own</GuestType>
  # 			<CRSNumber>c3344112929</CRSNumber>
  # 			<CheckGuestInAllowed>false</CheckGuestInAllowed>
  # 			<CheckGuestOutAllowed>false</CheckGuestOutAllowed>
  # 			<CurrencyCode>ca</CurrencyCode>
  # 			<TotalRateAmount>3245.69</TotalRateAmount>
  # 			<TotalRateAmountTaxes>259.66</TotalRateAmountTaxes>
  # 			<RoomRateAmount>1022.00</RoomRateAmount>
  # 			<RoomRateAmountTaxes>81.90</RoomRateAmountTaxes>
  # 			<ResortFee>69.93</ResortFee>
  # 			<ResortFeeTaxes>5.59</ResortFeeTaxes>
  # 			<HousekeepingFee>0.00</HousekeepingFee>
  # 			<HousekeepingFeeTaxes>0.00</HousekeepingFeeTaxes>
  # 			<SpaFee>125.00</SpaFee>
  # 			<SpaFeeTaxes>10.00</SpaFeeTaxes>
  # 			<FirstRoomNightAmount>146.00</FirstRoomNightAmount>
  # 			<RoomRevenue>240.00</RoomRevenue>
  # 			<FoodRevenue>0.00</FoodRevenue>
  # 			<BanquetRevenue>0.00</BanquetRevenue>
  # 			<OtherRevenue>0.00</OtherRevenue>
  # 			<ReservationText>
  # 				<Text>Guest has indicated that they are arriving early and they</Text>
  # 				<Text>would like us to do what we can to have a room ready for</Text>
  # 				<Text>them if at all possible.</Text>
  # 			</ReservationText>
  # 			<SharerInfo>
  # 				<SharerReservationNumber>321123</SharerReservationNumber>
  # 			</SharerInfo>
  # 			<Group>
  # 				<GroupReservation>12345677</GroupReservation>
  # 				<Name>Millers Ski Group</Name>
  # 			</Group>
  # 			<SpecialRequests>crib,roll</SpecialRequests>
  # 			<VehicleInfo>
  # 				<VehicleMake>toyota</VehicleMake>
  # 				<VehicleColor>ice blue</VehicleColor>
  # 				<VehicleModel>prius</VehicleModel>
  # 				<VehicleLicense>ccwq1234</VehicleLicense>
  # 				<VehicleStateProv>on</VehicleStateProv>
  # 				<VehicleParkingNumber>11223344</VehicleParkingNumber>
  # 			</VehicleInfo>
  # 			<ReservationDateInfo>
  # 				<ReservationDateDetails>
  # 					<ReservationDate>2015-09-27</ReservationDate>
  # 					<RoomRevenue>120.00</RoomRevenue>
  # 					<FoodRevenue>0.00</FoodRevenue>
  # 					<BanquetRevenue>0.00</BanquetRevenue>
  # 					<OtherRevenue>0.00</OtherRevenue>
  # 				</ReservationDateDetails>
  # 			</ReservationDateInfo>
  # 			<ReservationDateInfo>
  # 				<ReservationDateDetails>
  # 					<ReservationDate>2015-09-28</ReservationDate>
  # 					<RoomRevenue>120.00</RoomRevenue>
  # 					<FoodRevenue>0.00</FoodRevenue>
  # 					<BanquetRevenue>0.00</BanquetRevenue>
  # 					<OtherRevenue>0.00</OtherRevenue>
  # 				</ReservationDateDetails>
  # 			</ReservationDateInfo>
  # 		</ReservationData>
  # 	</Reservations>
  # </Request>

  def process_roommove(params)
    # process received rom moves
    #
    # Example:
    # 	process_roommove( client_api_integration: ClientApiIntegration, data: Array, hotel_id: String, password_hash: String )
    #
    # Required Parameters:
    # 	data:                   (Array)
    # 	hotel_id:               (String)
    # 	password_hash:          (String)
    # 	client_api_integration: (ClientApiIntegration)
    #
    # Optional Parameters:
    #   none
    #
    client_api_integration = params.include?(:client_api_integration) && params[:client_api_integration].is_a?(ClientApiIntegration) ? params[:client_api_integration] : nil
    hotel_id               = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''
    password_hash          = params.include?(:password_hash) ? params[:password_hash].to_s : ''
    data                   = params.include?(:data) ? params[:data] : []
    data                   = Array(data)
    response               = {
      'Version'      => '1.0',
      'HotelId'      => hotel_id,
      'PasswordHash' => password_hash,
      'Status'       => 'failure',
      'Message'      => 'unexpected data received'
    }

    if client_api_integration

      data.each do |guest_info|
        contact = client_api_integration.client.contacts.joins(:contact_api_integrations).where("contact_api_integrations.data->>'client_code' = '#{guest_info['ClientCode']}'").first

        unless contact
          contact_phone = guest_info['Cell'].to_s.clean_phone(client_api_integration.client.primary_area_code)
          contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: client_api_integration.client_id, phones: { contact_phone => 'mobile' }, emails: [guest_info['EmailAddress'].to_s]) if contact_phone.length == 10
        end

        if contact
          contact.lastname  = guest_info['LastName'].to_s
          contact.firstname = guest_info['FirstName'].to_s
          contact.email     = guest_info['EmailAddress'].to_s
          contact.ok2email  = guest_info['EmailOptOut'].to_s.casecmp?('false') ? 0 : 1

          if contact.save
            contact_api_integration = contact.contact_api_integrations.find_or_initialize_by(target: 'maestro')

            if contact_api_integration
              contact_api_integration.client_code    = guest_info['ClientCode'].to_s
              contact_api_integration.arrival_date   = ActiveSupport::TimeZone['UTC'].parse(guest_info['ArrivalDate'].to_s)
              contact_api_integration.departure_date = ActiveSupport::TimeZone['UTC'].parse(guest_info['DepartureDate'].to_s)
              contact_api_integration.room_number    = guest_info['RoomCode'].to_s
              contact_api_integration.save

              # update Custom Fields
              update_contact_custom_fields(client_api_integration:, contact_api_integration:)
            end

            campaign_id       = client_api_integration.roommove_contact_actions.include?('campaign_id') ? client_api_integration.roommove_contact_actions['campaign_id'].to_i : 0
            group_id          = client_api_integration.roommove_contact_actions.include?('group_id') ? client_api_integration.roommove_contact_actions['group_id'].to_i : 0
            stage_id          = client_api_integration.roommove_contact_actions.include?('stage_id') ? client_api_integration.roommove_contact_actions['stage_id'].to_i : 0
            tag_id            = client_api_integration.roommove_contact_actions.include?('tag_id') ? client_api_integration.roommove_contact_actions['tag_id'].to_i : 0
            stop_campaign_ids = client_api_integration.roommove_contact_actions['stop_campaign_ids']

            contact.process_actions(
              campaign_id:,
              group_id:,
              stage_id:,
              tag_id:,
              stop_campaign_ids:
            )
          end
        end
      end

      response['Status']  = 'success'
      response['Message'] = ''
    end

    response
  end
  # <?xml version=”1.0” encoding=”utf-8”?>
  # <Request>
  # 	<Version>1.0</Version>
  # 	<HotelId>0005a</HotelId>
  # 	<PasswordHash>0102030405060708090a0b0c0d0e0f</PasswordHash>
  # 	<Action>RoomMove</Action>
  # 	<SourceRoomInformation>
  # 		<GuestInfo>
  # 			<GuestName>Decker, Eric</GuestName>
  # 			<LastName>Decker</LastName>
  # 			<FirstName>Eric</FirstName>
  # 			<Salutation>Mr.</Salutation>
  # 			<ZipCode>90210</ZipCode>
  # 			<Country>US</Country>
  # 			<EmailAddress>ericd@gmail.com</EmailAddress>
  # 			<Cell>201-333-2323</Cell>
  # 			<Language>en</Language>
  # 			<Vip>v</Vip>
  # 			<AccountNumber>d2134511</AccountNumber>
  # 			<EmailOptOut>false</EmailOptOut>
  # 			<RegularMailOptOut>false</RegularMailOptOut>
  # 			<DateOfBirth>1972-11-03</DateOfBirth>
  # 			<ReservationNumber>123456678</ReservationNumber>
  # 			<ReservationNumberKey>123456678-1</ReservationNumberKey>
  # 			<ArrivalDate>2014-09-20T15:30:00-5:00</ArrivalDate>
  # 			<DepartureDate>2014-09-22T11:00:00-5:00</DepartureDate>
  # 			<BookingDate>2014-03-08T10:21:00-5:00</BookingDate>
  # 			<ReservationLastModifyDate>2014-07-19T10:13:00-5:00</ReservationLastModifyDate>
  # 			<BuildingCode>bld</BuildingCode>
  # 			<RoomCode>0201</RoomCode>
  # 			<RoomTypeCode>king</RoomTypeCode>
  # 			<RoomTypeDescription>king bed, city view</RoomTypeDescription>
  # 		</GuestInfo>
  # 		<HousekeepingStatus>vd</HousekeepingStatus>
  # 		<HousekeepingStatusDescription>vacant dirty</HousekeepingStatusDescription>
  # 	</SourceRoomInformation>
  # 	<DestinationRoomInformation>
  # 		<GuestInfo>
  # 			<GuestName>Decker, Eric</GuestName>
  # 			<LastName>Decker</LastName>
  # 			<FirstName>Eric</FirstName>
  # 			<Salutation>Mr.</Salutation>
  # 			<ZipCode>90210</ZipCode>
  # 			<Country>US</Country>
  # 			<EmailAddress>ericd@gmail.com</EmailAddress>
  # 			<Cell>201-333-2323</Cell>
  # 			<Language>en</Language>
  # 			<Vip>v</Vip>
  # 			<AccountNumber>d2134511</AccountNumber>
  # 			<EmailOptOut>false</EmailOptOut>
  # 			<RegularMailOptOut>false</RegularMailOptOut>
  # 			<DateOfBirth>1972-11-03</DateOfBirth>
  # 			<ReservationNumber>123456678</ReservationNumber>
  # 			<ReservationNumberKey>123456678-1</ReservationNumberKey>
  # 			<ArrivalDate>2014-09-22T15:30:00-5:00</ArrivalDate>
  # 			<DepartureDate>2014-09-27T11:00:00-5:00</DepartureDate>
  # 			<BookingDate>2014-03-08T10:21:00-5:00</BookingDate>
  # 			<ReservationLastModifyDate>2014-07-12T09:01:00-5:00</ReservationLastModifyDate>
  # 			<Adults>3</Adults>
  # 			<Children>1</Children>
  # 			<BuildingCode>bld</BuildingCode>
  # 			<RoomCode>0405</RoomCode>
  # 			<RoomTypeCode>king</RoomTypeCode>
  # 			<RoomTypeDescription>king bed, city view</RoomTypeDescription>
  # 			<GuestSelection>1</GuestSelection>
  # 			<FolioNumber>56432</FolioNumber>
  # 			<CreditAvailable>300.00</CreditAvailable>
  # 			<PostRestrictions>0</PostRestrictions>
  # 			<TelephoneRestrictions>0</TelephoneRestrictions>
  # 			<GroupTypeCode>conf</GroupTypeCode>
  # 			<Source>nytimes</Source>
  # 			<SubSource>fallpromo</SubSource>
  # 			<ComplimentaryUse>false</ComplimentaryUse>
  # 			<HouseUse>false</HouseUse>
  # 			<MealPlan>mpa</MealPlan>
  # 			<RateType>unlimited</RateType>
  # 			<TotalRateAmount>3245.69</TotalRateAmount>
  # 			<TotalRateAmountTaxes>259.66</TotalRateAmountTaxes>
  # 			<RoomRateAmount>1022.00</RoomRateAmount>
  # 			<RoomRateAmountTaxes>81.90</RoomRateAmountTaxes>
  # 			<ResortFee>69.93</ResortFee>
  # 			<ResortFeeTaxes>5.59</ResortFeeTaxes>
  # 			<HousekeepingFee>0.00</HousekeepingFee>
  # 			<HousekeepingFeeTaxes>0.00</HousekeepingFeeTaxes>
  # 			<SpaFee>125.00</SpaFee>
  # 			<SpaFeeTaxes>10.00</SpaFeeTaxes>
  # 			<FirstRoomNightAmount>146.00</FirstRoomNightAmount>
  # 			<ReservationText>
  # 				<Text>Guest has indicated that they are arriving early and they</Text>
  # 				<Text>would like us to do what we can to have a room ready for</Text>
  # 				<Text>them if at all possible.</Text>
  # 			</ReservationText>
  # 			<SharerInfo>
  # 				<SharerReservationNumber>321123</SharerReservationNumber>
  # 			</SharerInfo>
  # 			<Group>
  # 				<GroupReservation>12345677</GroupReservation>
  # 				<Name>Millers Ski Group</Name>
  # 			</Group>
  # 		</GuestInfo>
  # 		<HousekeepingStatus>od</HousekeepingStatus>
  # 		<HousekeepingStatusDescription>occupied dirty</HousekeepingStatusDescription>
  # 	</DestinationRoomInformation>
  # </Request>

  def salt_request_response(params)
    # receive a salt request and create a response
    #
    # Example:
    # 	Maestro.new.salt_request_response( hotel_id: String )
    #
    # Required Parameters:
    # 	hotel_id: (String)
    #
    # Optional Parameters:
    #   none
    #
    response = {
      'Version' => '1.0',
      'Status'  => 'failure',
      'Message' => 'unexpected Hotel ID'
    }
    hotel_id = params.include?(:hotel_id) ? params[:hotel_id].to_s : ''

    if hotel_id.present?
      client_api_integration = ClientApiIntegration.find_by(target: 'maestro', api_key: hotel_id)

      if client_api_integration
        salt = RandomCode.new.salt(10)
        client_api_integration.salt_responses[salt] = Time.current
        client_api_integration.save
        response = {
          'Version' => '1.0',
          'HotelId' => hotel_id,
          'Salt'    => salt
        }
      end
    end

    response
  end

  def salt_request_send(args)
    # send a salt request
    #
    # Example:
    # 	Maestro.new.salt_request_send( hotel_id: String, tenant: String )
    #
    # Required Arguments:
    # 	hotel_id: (String)
    # 	tenant:   (String)
    #
    # Optional Arguments:
    #   none
    #
    tenant   = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
    hotel_id = args.include?(:hotel_id) ? args[:hotel_id].to_s : ''

    return if hotel_id.blank?

    request = {
      'Version' => '1.0',
      'HotelId' => hotel_id,
      'GetSalt' => nil
    }

    conn = Faraday.new(url: base_url(tenant:))
    conn.post '', request.to_xml(root: 'Request')
  end

  # private

  def update_contact_custom_fields(params)
    # update ContactCustomFields from ContactApiIntegration
    #
    # Example:
    # 	update_contact_custom_fields( client_api_integration: client_api_integration, contact_api_integration: contact_api_integration )
    #
    # Required Parameters:
    # 	client_api_integration:  (ClientApiIntegration)
    # 	contact_api_integration: (ContactApiIntegration)
    #
    # Optional Parameters:
    #   none
    #
    client_api_integration  = params.include?(:client_api_integration) && params[:client_api_integration].is_a?(ClientApiIntegration) ? params[:client_api_integration] : nil
    contact_api_integration = params.include?(:contact_api_integration) && params[:contact_api_integration].is_a?(ContactApiIntegration) ? params[:contact_api_integration] : nil

    return unless client_api_integration && contact_api_integration

    %w[status checked_in guest_type client_code room_number arrival_date departure_date].each do |field|
      if client_api_integration.custom_field_assignments.include?(field) && client_api_integration.custom_field_assignments[field].to_i.positive?
        client_custom_field = client_api_integration.client.client_custom_fields.find_by(id: client_api_integration.custom_field_assignments[field].to_i)

        if client_custom_field
          contact_custom_field = contact_api_integration.contact.contact_custom_fields.find_or_initialize_by(client_custom_field_id: client_custom_field.id)
          contact_custom_field.update(var_value: contact_api_integration.public_send(field.to_sym))
        end
      end
    end
  end

  def base_url(args)
    tenant        = args.include?(:tenant) && args[:tenant].to_s.present? ? args[:tenant].to_s : 'chiirp'
    tenant_domain = I18n.with_locale(tenant) { I18n.t('tenant.domain') }

    if Rails.env.production?
      "https://app.#{tenant_domain}/integrations/maestro/endpoint"
    else
      "https://dev.#{tenant_domain}/integrations/maestro/endpoint"
    end
  end
end
