# frozen_string_literal: true

# app/lib/sunbase_data.rb
module SunbaseData
  # process various API calls to SunbaseData

  def self.send_appt(params)
    # send a lead to SunbaseData
    #
    # Example:
    # 	SunbaseData.send_appt( api_key: String, sales_rep_id: String, appt_setter_id: String, appt: Time )
    #
    # Required Parameters:
    # 	api_key:        (String)
    # 	sales_rep_id:   (String)
    # 	appt_setter_id: (String)
    # 	appt:           (Time)
    #
    # Optional Parameters:
    #   firstname:      (String)
    # 	lastname:       (String)
    # 	address1:       (String)
    # 	address2:       (String)
    # 	city:           (String)
    # 	state:          (String)
    # 	zip:            (String)
    # 	phone:          (String)
    # 	email:          (String)
    #
    api_key        = (params[:api_key] || '').to_s
    sales_rep_id   = (params[:sales_rep_id] || '').to_s
    appt_setter_id = (params[:appt_setter_id] || '').to_s
    appt           = (params[:appt] || nil)

    firstname      = (params[:firstname] || '').to_s
    lastname       = (params[:lastname] || '').to_s
    address1       = (params[:address1] || '').to_s
    address2       = (params[:address2] || '').to_s
    city           = (params[:city] || '').to_s
    state          = (params[:state] || '').to_s
    zipcode        = (params[:zipcode] || '').to_s
    phone          = (params[:phone] || '').to_s
    email          = (params[:email] || '').to_s

    response       = { success: false, accepted: false, error_code: '', error_message: '' }

    if api_key.present? && phone.present?
      # api_key, channel & phone was received

      data = {}
      data['schema_name'] = api_key
      data['salesRep']    = sales_rep_id
      data['apptSetter']  = appt_setter_id
      data['lead_source'] = 'CHIIRP'

      data['first_name']  = firstname if firstname.present?
      data['last_name']   = lastname if lastname.present?
      data['address1']    = address1 if address1.present?
      data['address2']    = address2 if address2.present?
      data['city']        = city if city.present?
      data['state']       = state if state.present?
      data['zip_code']    = zipcode if zipcode.present?
      data['phone']       = phone if phone.present?
      data['email']       = email if email.present?

      # SunbaseData accepts apptTime in local time / do NOT convert to UTC
      data['apptTime']    = appt.strftime('%FT%T') if appt.respond_to?(:strftime)

      begin
        conn = Faraday.new(url: base_url)

        result = conn.post '', data

        if result.status.to_i == 200
          response[:success]  = true
          # rubocop:disable Rails/OutputSafety
          response[:accepted] = result.body.html_safe
          # rubocop:enable Rails/OutputSafety
        else
          response[:error_code]    = defined?(result) && defined?(result.status) ? result.status : ''
          response[:error_message] = defined?(result) && defined?(result.reason_phrase) ? result.reason_phrase : ''
        end
      rescue StandardError => e
        # Something else happened
        response[:error_code]    = defined?(result) && defined?(result.status) ? result.status : ''
        response[:error_message] = defined?(result) && defined?(result.reason_phrase) ? result.reason_phrase : ''

        ProcessError::Report.send(
          error_code:    response[:error_code],
          error_message: response[:error_message],
          variables:     {
            params:   params.inspect,
            data:     data.inspect,
            e:        e.inspect,
            result:   result.inspect,
            response: response.inspect
          },
          file:          __FILE__,
          line:          __LINE__
        )
      end
    end

    response
  end

  def self.base_url
    'https://server2.sunbasedata.com/sunbase/portal/api/lead_post.jsp'
  end

  #### API Notes
  # Endpoint url https://server2.sunbasedata.com/sunbase/portal/api/lead_post.jsp

  # schema_name=mysolarsun (Required) (use this name, that way we can map it to their system)
  # first_name leads first name (Required)
  # last_name leads last name (Required)
  # address1 - The address component
  # address2 - The address component (often used for suite or appt)
  # city - the city of the lead
  # state - the state that the lead lives in
  # zip_code - zip code of the lead
  # county - the county that the lead belongs to
  # customField1 - utility company. if not relevant omit
  # customField37 - power bill (just a number no $, decimal is fine). if not relevant omit
  # customField30 - # of people. if not relevant omit
  # lead_cost - lead cost (example 20 for 20 dollars)
  # email - the email address of the lead
  # phone - the phone for the lead
  # comments - Comments
  # lead_source - the name of the source of the lead (For example LeadCompany)
  # lead_other - some companies put the lead id in here
  # apptTime - The appointment time in the form yyyy-MM-DDTHH:mm like (2018-12-31T12:59)

  # EXTRA FIELDS:

  # Property type = customfield18
  # Tree Removal   = customfield25
  # How Many Trees Removed = customfield20
  # Household Income = customfield21
  # Mortgage Late Payments Last 12 Months  = customfield22
  # Bankruptcy or Foreclosure Last 3 Years = customfield24
end
