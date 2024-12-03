# frozen_string_literal: true

# app/lib/xencall.rb
module Xencall
  # process various API calls to Xencall

  def self.send_lead(args)
    # send a lead to Xencall
    #
    # Example:
    # 	Xencall.send_lead( api_key: String, phone: String )
    #
    # Required Arguments:
    # 	api_key:             (String)
    # 	phone:               (String)
    # 	channel:             (String)
    #
    # Optional Arguments:
    #   firstname:           (String)
    # 	lastname:            (String)
    # 	address:             (String)
    # 	city:                (String)
    # 	state:               (String)
    # 	zip:                 (String)
    # 	country:             (String)
    # 	phone_alt:           (String)
    # 	email:               (String)
    # 	lead_date:           (String)
    # 	st_customer_id:      (String)
    # 	contact_id:          (String)
    # 	custom_field_name:   (String)
    # 	custom_field_string: (String)
    #
    api_key             = args.include?(:api_key) ? args[:api_key].to_s : ''
    channel             = args.include?(:channel) ? args[:channel].to_s : ''
    phone               = args.include?(:phone) ? args[:phone].to_s.clean_phone : ''
    firstname           = args.include?(:firstname) ? args[:firstname].to_s : ''
    lastname            = args.include?(:lastname) ? args[:lastname].to_s : ''
    address             = args.include?(:address) ? args[:address].to_s : ''
    city                = args.include?(:city) ? args[:city].to_s : ''
    state               = args.include?(:state) ? args[:state].to_s : ''
    zip                 = args.include?(:zip) ? args[:zip].to_s : ''
    country             = args.include?(:country) ? args[:country].to_s : ''
    phone_alt           = args.include?(:phone_alt) ? args[:phone_alt].to_s : ''
    email               = args.include?(:email) ? args[:email].to_s : ''
    lead_date           = args.include?(:lead_date) ? args[:lead_date].to_s : ''
    test_send           = args.include?(:test_send) && args[:test_send].is_a?(Boolean) ? args[:test_send] : false
    st_customer_id      = args.include?(:st_customer_id) ? args[:st_customer_id].to_s : ''
    contact_id          = args.include?(:contact_id) ? args[:contact_id].to_i : 0
    custom_field_name   = args.include?(:custom_field_name) ? args[:custom_field_name].to_s : ''
    custom_field_string = args.include?(:custom_field_string) ? args[:custom_field_string].to_s : ''
    response            = { success: false, accepted: false, xencall_lead_id: nil, error_code: '', error_message: '' }

    # replace placeholders with data
    # rubocop:disable Lint/InterpolationCheck
    custom_field_string = custom_field_string.gsub('#{id}', contact_id.to_s).gsub('#{st_id}', st_customer_id)
    # rubocop:enable Lint/InterpolationCheck

    if api_key.present? && channel.present? && phone.present?
      # api_key, channel & phone was received

      data = {}
      data['lead'] = {}
      data['lead']['0'] = { 'phone' => phone }
      data['lead']['0']['firstName']         = firstname if firstname.present?
      data['lead']['0']['lastName']          = lastname if lastname.present?
      data['lead']['0']['address']           = address if address.present?
      data['lead']['0']['city']              = city if city.present?
      data['lead']['0']['state']             = state if state.present?
      data['lead']['0']['zip']               = zip if zip.present?
      data['lead']['0']['country']           = country if country.present?
      data['lead']['0']['phone2']            = phone_alt if phone_alt.present?
      data['lead']['0']['email']             = email if email.present?
      data['lead']['0']['lead_date']         = lead_date if lead_date.present?
      data['lead']['0'][custom_field_name]   = custom_field_string if custom_field_name.present? && custom_field_string.present?
      data['test'] = 1 if test_send
      # Rails.logger.info "data: #{data.inspect} - File: #{__FILE__} - Line: #{__LINE__} - Calling: { File: #{caller_locations(1..1).first.path} - Line: #{caller_locations(1..1).first.lineno} }"

      begin
        conn = Faraday.new(url: base_url(api_key) + "lead-api/#{channel}")

        result = conn.post '', data

        if result.status == 200
          body = JSON.parse(result.body)

          if body['0']['Success'] == true
            response[:success]         = true
            response[:accepted]        = body['0']['Accepted']
            response[:xencall_lead_id] = body['0']['xencall_leadId']
          else
            response[:error_code]    = '??'
            response[:error_message] = body['0']['Error']
          end
        else
          response[:error_code]    = result.status
          response[:error_message] = result.reason_phrase
        end
      rescue StandardError => e
        # Something else happened
        response[:error_code]    = defined?(result) && defined?(result.status) ? result.status : ''
        response[:error_message] = defined?(result) && defined?(result.reason_phrase) ? result.reason_phrase : ''

        ProcessError::Report.send(
          error_message: "Xencall::Error: #{e.message}",
          variables:     {
            args:     args.inspect,
            e:        e.inspect,
            response: response.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end
    end

    response
  end
  # post
  # {
  # 	"lead" => {
  # 		"0" => {
  # 			"firstName" => "Kevin",
  # 			"lastName" => "",
  # 			"phone" => "8025551234",
  # 			"phone2" => "",
  # 			"address" => "",
  # 			"city" => "",
  # 			"state" => "",
  # 			"zip" => "",
  # 			"country" => "",
  # 			"email" => "",
  # 			"lead_date" => "",
  # 			"times_called" => ""
  # 		}
  # 	},
  # 	"test"=>"1"
  # }

  # response
  # {
  # 	"0": {
  # 		"Success": true,
  # 		"Accepted": false,
  # 		"xencall_leadId": "TestLead:29803"
  # 	}
  # }

  def self.base_url(api_key)
    "https://#{api_key}.xencall.com/"
  end
end
