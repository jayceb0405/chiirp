# frozen_string_literal: true

# app/controllers/integrations/jotform/integrations_controller.rb
module Integrations
  module Jotform
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:endpoint]
      before_action :authenticate_user!, except: %i[endpoint]
      before_action :user_api_integration, except: %i[endpoint]

      CURRENT_VERSION = '1'

      # (GET/POST)
      # /integrations/jotform/integration/endpoint
      # integrations_jotform_integration_endpoint_path
      # integrations_jotform_integration_endpoint_url
      def endpoint
        form_id = params.dig('formID').to_s
        raw_request = JSON.parse(params.dig('rawRequest') || '{}')
        lead = {}

        raw_request.each do |key, value|
          key_split = key.split('_')

          if key_split.length > 1 && key_split[0][0] == 'q'

            if value.is_a?(Hash)
              lead[key_split[0].sub('q', '')] = {}

              value.each do |var_name, value_01|
                lead[key_split[0].sub('q', '')][var_name] = value_01
              end
            else
              lead[key_split[0].sub('q', '')] = value
            end
          end
        end

        return if form_id.empty? || lead.empty?

        begin
          UserApiIntegration.where(target: 'jotform').where("(data -> 'jotform_forms' ->> ?) IS NOT NULL", form_id).find_each do |user_api_integration|
            internal_fields = ::Webhook.internal_key_hash(user_api_integration.user.client, 'contact', %w[personal ext_references]).keys
            custom_field_keys = user_api_integration.user.client.client_custom_fields.pluck(:id)

            if (form = user_api_integration.jotform_forms.dig(form_id))
              # process lead
              contact_data          = {}
              phone_numbers         = {}
              contact_custom_fields = {}
              emails                = []
              campaign_ids          = form['campaign_id'].positive? ? [form['campaign_id']] : []
              ok2                   = %w[ok2text ok2email]
              controls_02           = %w[control_datetime control_fullname control_phone]

              form['questions'].each do |question_id, question|
                if !question['sublabels'].empty?

                  question['sublabels'].each do |var_name, sublabel|
                    if internal_fields.include?(sublabel['custom_field_id'])
                      emails << lead.dig(question_id, var_name).to_s if sublabel['custom_field_id'].include?('email')

                      if sublabel['custom_field_id'] == 'fullname'
                        fullname = lead.dig(question_id, var_name).to_s.parse_name
                        contact_data[:firstname] = fullname[:firstname]
                        contact_data[:lastname] = fullname[:lastname]
                      else
                        contact_data[sublabel['custom_field_id'].to_sym] = lead.dig(question_id, var_name).to_s
                      end
                    elsif custom_field_keys.include?(sublabel['custom_field_id'].to_i)
                      contact_custom_fields[sublabel['custom_field_id'].to_i] = lead.dig(question_id, var_name).to_s
                    elsif sublabel['custom_field_id'].include?('phone_') && lead.dig(question_id, var_name)
                      phone_numbers[lead.dig(question_id, var_name).to_s.clean_phone(user_api_integration.user.client.primary_area_code)] = sublabel['custom_field_id'].gsub('phone_', '')
                    elsif ok2.include?(sublabel['custom_field_id'])
                      contact_data[sublabel['custom_field_id'].to_sym] = lead.dig(question_id, var_name).to_s.is_yes? ? 1 : 0
                    end
                  end
                elsif controls_02.include?(question.dig('type'))

                  case question['type']
                  when 'control_datetime'
                    value = "#{lead.dig(question_id, 'year')}-#{lead.dig(question_id, 'month')}-#{lead.dig(question_id, 'day')}"

                    value += if lead.dig(question_id, 'hour') && lead.dig(question_id, 'min')
                               " #{lead.dig(question_id, 'hour')}:#{lead.dig(question_id, 'min')}"
                             else
                               '00:00'
                             end

                    value += " #{lead.dig(question_id, 'ampm')}" if lead.dig(question_id, 'ampm')
                    value = (Time.use_zone(user_api_integration.user.client.time_zone) { Chronic.parse(value) }).to_s
                  when 'control_fullname'
                    value = [lead.dig(question_id, 'prefix').to_s, lead.dig(question_id, 'first').to_s, lead.dig(question_id, 'middle').to_s, lead.dig(question_id, 'last').to_s, lead.dig(question_id, 'suffix').to_s]
                    value.delete('')
                    value = value.join(' ')
                  when 'control_phone'

                    if lead.dig(question_id, 'area') && lead.dig(question_id, 'phone')
                      value = (lead.dig(question_id, 'area').to_s + lead.dig(question_id, 'phone').to_s).clean_phone(user_api_integration.user.client.primary_area_code)
                    elsif lead.dig(question_id, 'full')
                      value = lead.dig(question_id, 'full').to_s.clean_phone(user_api_integration.user.client.primary_area_code)
                    end
                  else
                    value = ''
                  end

                  if internal_fields.include?(question['custom_field_id'])
                    emails << value if question['custom_field_id'].include?('email')

                    if question['custom_field_id'] == 'fullname'
                      fullname = value.to_s.parse_name
                      contact_data[:firstname] = fullname[:firstname]
                      contact_data[:lastname] = fullname[:lastname]
                    else
                      contact_data[question['custom_field_id'].to_sym] = value
                    end
                  elsif custom_field_keys.include?(question['custom_field_id'].to_i)
                    contact_custom_fields[question['custom_field_id'].to_i] = value
                  elsif question['custom_field_id'].include?('phone_') && !value.empty?
                    phone_numbers[value] = question['custom_field_id'].gsub('phone_', '')
                  elsif ok2.include?(question['custom_field_id'])
                    contact_data[question['custom_field_id'].to_sym] = value.downcase.is_yes? ? 1 : 0
                  end
                elsif internal_fields.include?(question['custom_field_id'])

                  emails << lead.dig(question_id).to_s if question['custom_field_id'].include?('email')

                  if question['custom_field_id'] == 'fullname'
                    fullname = lead.dig(question_id).to_s.parse_name
                    contact_data[:firstname] = fullname[:firstname]
                    contact_data[:lastname] = fullname[:lastname]
                  else
                    contact_data[question['custom_field_id'].to_sym] = lead.dig(question_id).to_s
                  end
                elsif custom_field_keys.include?(question['custom_field_id'].to_i)
                  contact_custom_fields[question['custom_field_id'].to_i] = lead.dig(question_id).to_s
                elsif question['custom_field_id'].include?('phone_') && lead.dig(question_id)
                  phone_numbers[lead.dig(question_id).to_s.clean_phone(user_api_integration.user.client.primary_area_code)] = question['custom_field_id'].gsub('phone_', '')
                elsif ok2.include?(question['custom_field_id'])
                  contact_data[question['custom_field_id'].to_sym] = lead.dig(question_id).to_s.is_yes? ? 1 : 0
                end

                question['options'].each do |option_text, campaign_id|
                  campaign_ids << campaign_id if lead.dig(question_id) == option_text
                end
              end

              contact = if phone_numbers.empty? && emails.empty?
                          user_api_integration.user.contacts.new
                        else
                          Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: user_api_integration.user.client_id, phones: phone_numbers, emails:)
                        end

              if contact.update(contact_data)
                # save any ContactCustomFields
                contact.update_custom_fields(custom_fields: contact_custom_fields) if contact_custom_fields.present?

                campaign_ids.each do |campaign_id|
                  # start new Campaign for the
                  Contacts::Campaigns::StartJob.perform_later(
                    campaign_id:,
                    client_id:   contact.client_id,
                    contact_id:  contact.id,
                    user_id:     contact.user_id
                  )
                end
              end
            end
          end
        rescue StandardError => e
          e.set_backtrace(BC.new.clean(caller))

          Appsignal.report_error(e) do |transaction|
            # Only needed if it needs to be different or there's no active transaction from which to inherit it
            Appsignal.set_action('Integrations::Jotform::IntegrationsController#endpoint')

            # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
            Appsignal.add_params(params)

            Appsignal.set_tags(
              error_level: 'error',
              error_code:  0
            )
            Appsignal.add_custom_data(
              form_id:,
              raw_request:,
              lead:,
              file:        __FILE__,
              line:        __LINE__
            )
          end
        end

        render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
      end
      # example 01: jotform > submission
      # {
      # 	"formID"=>"201954131511141",
      # 	"submissionID"=>"4706291710117358645",
      # 	"webhookURL"=>"https://dev.chiirp.com/integrations/jotform/integration/endpoint",
      # 	"ip"=>"209.134.39.110",
      # 	"formTitle"=>"Client Registration",
      # 	"pretty"=>"Date:07 15 2020, Contact person:Kevin Neubert, Business name:, Street address:, Street address line 2:, City:, State:, Zip code:, E-mail address:kevinneub@kevinneubert.com, LinkedIn/online profile url :, Contact person:, Business name:, Street address:, Street address line 2:, City:, State:, Zip code:, Contact person:, Business name:, Street address:, Street address line 2:, City:, State:, Zip code:, Specific Registration Requests/Details:, Would you like to receive our monthly e-mail?:Yes, Would you like to participate in our client surveys?:Yes, Billing Address:, Shipping Address:",
      # 	"username"=>"kevinneubchiirp",
      # 	"rawRequest"=>{
      # 		"slug"=>"submit/201954131511141/",
      # 		"q4_Date"=>{"month"=>"07", "day"=>"15", "year"=>"2020"},
      # 		"q7_Contact_person"=>"Kevin Neubert",
      # 		"q8_Business_name"=>"",
      # 		"q9_Street_address"=>"",
      # 		"q10_Street_address_line_2"=>"",
      # 		"q11_City"=>"",
      # 		"q12_State"=>"",
      # 		"q13_Zip_code"=>"",
      # 		"q14_E-mail_address"=>"kevinneub@kevinneubert.com",
      # 		"q15_LinkedIn/online_profile_url_"=>"",
      # 		"q17_Billing_Address"=>"",
      # 		"q18_Contact_person"=>"",
      # 		"q19_Business_name"=>"",
      # 		"q20_Street_address"=>"",
      # 		"q21_Street_address_line_2"=>"",
      # 		"q22_City"=>"",
      # 		"q23_State"=>"",
      # 		"q24_Zip_code"=>"",
      # 		"q26_Shipping_Address"=>"",
      # 		"q27_Contact_person"=>"",
      # 		"q28_Business_name"=>"",
      # 		"q29_Street_address"=>"",
      # 		"q30_Street_address_line_2"=>"",
      # 		"q31_City"=>"",
      # 		"q32_State"=>"",
      # 		"q33_Zip_code"=>"",
      # 		"q35_Specific_Registration_Requests/Details"=>"",
      # 		"q35_Specific Registration Requests/Details"=>""
      # 		"q38_Would_you_like_to_receive_our_monthly_e-mail?"=>"Yes",
      # 		"q39_Would_you_like_to_participate_in_our_client_surveys?"=>"Yes",
      # 		"event_id"=>"1594819922931_201954131511141_Xuz30Zc",
      # 	},
      # 	"type"=>"WEB"
      # }

      # example 02: jotform > submission
      # {
      # 	"formID"=>"201959031847056",
      # 	"submissionID"=>"4707341691265330272",
      # 	"webhookURL"=>"https://app.chiirp.com/integrations/jotform/integration/endpoint",
      # 	"ip"=>"139.60.66.21",
      # 	"formTitle"=>"30 Second Mortgage Quiz",
      # 	"pretty"=>"Zip Code:84005, What Type Of Home Are You Buying?:Single Family Home, How Will This Property Be Used?:Primary Home, Are You Currently Working With A Real Estate Agent?:YES, How Soon Are You Looking To Buy A Home?:Already Under Contract, Is This Your First Time Buying A House?:YES, What Is The Estimated Purchase Price Of The Property?:$5000 to $50,000, How Much Are You Putting Down For A Down Payment:0-5%, What Is Your Estimated Credit Score?:Excellent 720+, What Is Your Annual Income?:100000, Can You Provide Proof of Income?:YES, Have You Filed For Bankruptcy In The Past 7 years?:YES, Name:ryan fenn, Phone Number:909 8065762, Email:kjgkj@aj.com",
      # 	"username"=>"bueller82",
      # 	"rawRequest"=>"{
      # 		"slug":"submit/201959031847056",
      # 		"q1_zipCode":"84005",
      # 		"q3_whatType":"Single Family Home",
      # 		"q4_howWill":"Primary Home",
      # 		"q5_areYou":"YES",
      # 		"q6_howSoon":"Already Under Contract",
      # 		"q8_isThis":"YES",
      # 		"q19_whatIs":"$5000 to $50,000",
      # 		"q18_howMuch":"0-5%",
      # 		"q11_whatIs11":"Excellent 720+",
      # 		"q12_whatIs12":"100000",
      # 		"q13_canYou":"YES",
      # 		"q14_haveYou":"YES",
      # 		"q15_name":{
      # 			"first":"ryan",
      # 			"last":"fenn"
      # 		},
      # 		"q16_phoneNumber":{
      # 			"area":"909",
      # 			"phone":"8065762"
      # 		},
      # 		"q17_email":"kjgkj@aj.com",
      # 		"event_id":"1594924941034_201959031847056_jarYe3I"
      # 	}",
      # 	"type"=>"WEB"
      # }

      # (GET) show JotForm integration
      # /integrations/jotform
      # integrations_jotform_path
      # integrations_jotform_url
      def show
        path = if (version = user_api_integration&.data&.dig('version')).present?
                 send(:"integrations_jotform_v#{version}_path")
               else
                 send(:"integrations_jotform_v#{CURRENT_VERSION}_path")
               end

        respond_to do |format|
          format.js { render js: "window.location = '#{path}'" and return false }
          format.html { redirect_to path and return false }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('jotform')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access JotForm Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      def user_api_integration
        @user_api_integration = current_user.user_api_integrations.find_or_create_by(target: 'jotform', name: '')
      end
    end
  end
end
