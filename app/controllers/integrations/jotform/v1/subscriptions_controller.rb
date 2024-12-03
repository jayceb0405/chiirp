# frozen_string_literal: true

# app/controllers/integrations/jotform/v2024311/subscriptions_controller.rb
module Integrations
  module Jotform
    module V1
      class SubscriptionsController < Jotform::V1::IntegrationsController
        # (PUT/PATCH) create JotForm webhook for a form
        # /integrations/jotform/v1/subscriptions
        # integrations_jotform_v1_subscriptions_path
        # integrations_jotform_v1_subscriptions_url
        def update
          form_id = params.dig(:form_id).to_s
          webhook_id = params.dig(:webhook_id).to_s

          return if form_id.empty?

          jf_client = Integrations::JotForm::Jotform.new(@user_api_integration.api_key)

          if params.dig(:subscribe).to_bool
            jf_client.createFormWebhook(form_id, integrations_jotform_integration_endpoint_url)
          else
            jf_client.deleteFormWebhook(form_id, webhook_id) unless webhook_id.empty?
          end
        end

        private

        def form_params
          form_params = params.require(:forms)
          response = jotform_forms

          response.each do |form_id, form|
            response[form_id]['campaign_id'] = form_params.dig(form_id, 'campaign_id').to_i

            form['questions'].each do |question_id, question|
              if question.dig('sublabels').empty?
                response[form_id]['questions'][question_id]['custom_field_id'] = form_params.dig(form_id, question_id, 'custom_field_id').to_s

                question['options'].each do |option_text, _campaign_id|
                  response[form_id]['questions'][question_id]['options'][option_text] = form_params.dig(form_id, question_id, option_text).to_i
                end
              else

                question['sublabels'].each do |var_name, _sublabel|
                  response[form_id]['questions'][question_id]['sublabels'][var_name]['custom_field_id'] = form_params.dig(form_id, question_id, var_name, 'custom_field_id').to_s
                end
              end
            end
          end

          response
        end

        def jotform_forms
          response = {}

          begin
            jf_client   = Integrations::JotForm::Jotform.new(@user_api_integration.api_key)
            masked_full = %w[masked full]
            controls_01 = %w[control_button control_head control_image control_text]
            controls_02 = %w[control_datetime control_fullname control_phone]

            (jf_client.getForms || {}).each do |form|
              jotform_form = {}
              jotform_form['title']       = form['title']
              jotform_form['url']         = form['url']
              jotform_form['campaign_id'] = @user_api_integration.jotform_forms.dig(form['id'].to_s, 'campaign_id').to_i
              jotform_form['questions']   = {}

              (jf_client.getFormQuestions(form['id']) || {}).each do |_question_id, question|
                unless controls_01.include?(question['type'])

                  if controls_02.include?(question.dig('type'))
                    # this is a combo field
                    jotform_form['questions'][question['qid']] = {
                      'var_name'        => question['name'],
                      'label'           => question['text'],
                      'custom_field_id' => @user_api_integration.jotform_forms.dig(form['id'].to_s, 'questions', question['qid'].to_s, 'custom_field_id').to_s,
                      'options'         => {},
                      'sublabels'       => {},
                      'type'            => question.dig('type').to_s
                    }
                  else
                    jotform_form['questions'][question['qid']] = {
                      'var_name'        => question['name'],
                      'label'           => question['text'],
                      'custom_field_id' => @user_api_integration.jotform_forms.dig(form['id'].to_s, 'questions', question['qid'].to_s, 'custom_field_id').to_s
                    }

                    # collect options
                    jotform_options = {}

                    (question.dig('options') || '').split('|').each do |option|
                      jotform_options[option] = @user_api_integration.jotform_forms.dig(form['id'], 'questions', question['qid'], 'options', option).to_i
                    end

                    jotform_form['questions'][question['qid']]['options'] = jotform_options

                    # collect sublabels

                    jotform_sublabels = {}

                    (question.dig('sublabels') || {}).each do |var_name, label|
                      unless masked_full.include?(var_name) || label.empty?
                        jotform_sublabels[var_name] = {
                          'label'           => label,
                          'custom_field_id' => @user_api_integration.jotform_forms.dig(form['id'], 'questions', question['qid'], 'sublabels', var_name, 'custom_field_id').to_s
                        }
                      end
                    end

                    jotform_form['questions'][question['qid']]['sublabels'] = jotform_sublabels
                  end
                end
              end

              response[form['id']] = jotform_form
            end
          rescue StandardError => e
            e.set_backtrace(BC.new.clean(caller))

            Appsignal.report_error(e) do |transaction|
              # Only needed if it needs to be different or there's no active transaction from which to inherit it
              Appsignal.set_action('Integrations::Jotform::V1::SubscriptionsController#jotform_forms')

              # Only needed if you want to set different arguments or there's no active transaction from which to inherit it
              Appsignal.add_params(params)

              Appsignal.set_tags(
                error_level: 'error',
                error_code:  0
              )
              Appsignal.add_custom_data(
                response:,
                jotform_form: defined?(jotform_form) ? jotform_form : nil,
                form:         defined?(form) ? form : nil,
                question_id:  defined?(question_id) ? question_id : nil,
                question:     defined?(question) ? question : nil,
                option:       defined?(option) ? option : nil,
                name:         defined?(name) ? name : nil,
                label:        defined?(label) ? label : nil,
                file:         __FILE__,
                line:         __LINE__
              )
            end

            response = {}
          end

          response
        end
        # sample response
        # {
        # 	"form_id" => {
        # 		"title" => "Form Name",
        # 		"url" => "JotForm URL",
        # 		"questions" => {
        # 			"qid" => {
        # 				"var_name" => "variable_name",
        # 				"label" => "Label",
        # 				"custom_field_id" => "field_name",
        # 				"options" => {
        # 					"option_text" => "campaign_id",
        # 					"option_text" => "campaign_id", ...
        # 				},
        # 				"sublabels" => {
        # 					"var_name" => {
        # 						"label" => "Label",
        # 						"custom_field_id" => "field_name",
        # 					}, ...
        # 				},
        # 			}, ...
        # 		}
        # 	}, ...
        # }

        # getForms sample response
        # {
        # 	"responseCode": 200,
        # 	"message": "success",
        # 	"content": [{
        # 		"id": "31504059977966",
        # 		"username": "johnsmith",
        # 		"title": "Contact Us",
        # 		"height": "1550",
        # 		"url": "http://www.jotformpro.com/form/31504059977966",
        # 		"status": "ENABLED",
        # 		"created_at": "2013-06-24 18:43:21",
        # 		"updated_at": "2013-06-25 19:01:52",
        # 		"new": "5",
        # 		"count": "755"
        # 	}],
        # 	"limit-left": 4986
        # }

        # getFormQuestions sample response
        # {
        # 	"responseCode": 200,
        # 	"message": "success",
        # 	"content": {
        # 		"1": {
        # 			"hint": " ",
        # 			"labelAlign": "Auto",
        # 			"name": "textboxExample1",
        # 			"order": "1",
        # 			"qid": "1",
        # 			"readonly": "No",
        # 			"required": "No",
        # 			"shrink": "No",
        # 			"size": "20",
        # 			"text": "Textbox Example",
        # 			"type": "control_textbox",
        # 			"validation": "None"
        # 		},
        # 		"2": {
        # 			"labelAlign": "Auto",
        # 			"middle": "No",
        # 			"name": "fullName2",
        # 			"order": "1",
        # 			"prefix": "No",
        # 			"qid": "2",
        # 			"readonly": "No",
        # 			"required": "No",
        # 			"shrink": "Yes",
        # 			"sublabels":
        # 			{
        # 				"prefix": "Prefix",
        # 				"first": "First Name",
        # 				"middle": "Middle Name",
        # 				"last": "Last Name",
        # 				"suffix": "Suffix"
        # 			},
        # 			"suffix": "No",
        # 			"text": "Full Name",
        # 			"type": "control_fullname"
        # 		},
        # 		"3": {
        # 			"cols": "40",
        # 			"entryLimit": "None-0",
        # 			"labelAlign": "Auto",
        # 			"name": "yourMessage",
        # 			"order": "3",
        # 			"qid": "3",
        # 			"required": "No",
        # 			"rows": "6",
        # 			"text": "Your Message",
        # 			"type": "control_textarea",
        # 			"validation": "None"
        # 		},
        # 		"4": {
        # 			"compoundHint": "",
        # 			"countryCode": "No",
        # 			"description": "",
        # 			"inputMask": "disable",
        # 			"inputMaskValue": "(###) ###-####",
        # 			"labelAlign": "Auto",
        # 			"name": "phoneNumber",
        # 			"order": "14",
        # 			"qid": "4",
        # 			"readonly": "No",
        # 			"required": "No",
        # 			"sublabels": {
        # 				"country": "Country Code",
        # 				"area": "Area Code",
        # 				"phone": "Phone Number",
        # 				"full": "Phone Number",
        # 				"masked": ""
        # 			},
        # 			"text": "Phone Number",
        # 			"type": "control_phone"
        # 		},
        # 		"5": {
        # 			"allowCustomDomains": "No",
        # 			"allowedDomains": "",
        # 			"confirmation": "No",
        # 			"confirmationHint": "example@example.com",
        # 			"confirmationSublabel": "Confirm Email",
        # 			"defaultValue": "",
        # 			"description": "",
        # 			"disallowFree": "No",
        # 			"domainCheck": "No",
        # 			"hint": "",
        # 			"labelAlign": "Auto",
        # 			"maxsize": "",
        # 			"name": "email",
        # 			"order": "15",
        # 			"qid": "5",
        # 			"readonly": "No",
        # 			"required": "No",
        # 			"size": "30",
        # 			"subLabel": "example@example.com",
        # 			"text": "Email",
        # 			"type": "control_email",
        # 			"validation": "Email",
        # 			"verificationCode": "No"
        # 		},
        # 		"6": {
        # 			"allowOther": "No",
        # 			"calcValues": "",
        # 			"description": "",
        # 			"labelAlign": "Auto",
        # 			"name": "whatIs",
        # 			"options": "$5000 to $50,000|$50,001 to $100,000|$100,001 to $200,000|$200,001 to $300,000|$300,001 to $400,000|$400,001 to $500,000|$500,000+",
        # 			"order": "7",
        # 			"otherText": "Other",
        # 			"qid": "6",
        # 			"readonly": "No",
        # 			"required": "No",
        # 			"selected": "",
        # 			"shuffle": "No",
        # 			"special": "None",
        # 			"spreadCols": "2",
        # 			"text": "What Is The Estimated Purchase Price Of The Property?",
        # 			"type": "control_radio"
        # 		}
        # 	 	"7": {
        # 			"allowTime"=>"No",
        # 			"autoCalendar"=>"Yes",
        # 			"dateSeparator"=>"-",
        # 			"days"=>"[\"Sunday\",\"Monday\",\"Tuesday\",\"Wednesday\",\"Thursday\",\"Friday\",\"Saturday\",\"Sunday\"]",
        # 			"defaultTime"=>"Yes",
        # 			"format"=>"mmddyyyy",
        # 			"labelAlign"=>"Top",
        # 			"months"=>"[\"January\",\"February\",\"March\",\"April\",\"May\",\"June\",\"July\",\"August\",\"September\",\"October\",\"November\",\"December\"]",
        # 			"name"=>"Date",
        # 			"onlyFuture"=>"No",
        # 			"order"=>"4",
        # 			"other"=>"{\"today\":\"Today\"}",
        # 			"qid"=>"7",
        # 			"readonly"=>"No",
        # 			"required"=>"No",
        # 			"showDayPeriods"=>"both",
        # 			"startWeekOn"=>"Sunday",
        # 			"step"=>"10",
        # 			"sublabels"=>{
        # 				"day"=>"Day",
        # 				"month"=>"Month",
        # 				"year"=>"Year",
        # 				"last"=>"Last Name",
        # 				"hour"=>"Hour",
        # 				"minutes"=>"Minutes"
        # 			},
        # 			"text"=>"Date",
        # 			"timeFormat"=>"AM/PM",
        # 			"type"=>"control_datetime"
        # 	 	},
        # 	},
        # 	"limit-left": 4982
        # }
      end
    end
  end
end
