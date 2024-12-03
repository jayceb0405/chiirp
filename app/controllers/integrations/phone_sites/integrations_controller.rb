# frozen_string_literal: true

# app/controllers/integrations/phone_sites/integrations_controller.rb
module Integrations
  module PhoneSites
    class IntegrationsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:endpoint]
      before_action :authenticate_user!, only: %i[create destroy edit edit_forms instructions show update_forms]
      before_action :authorize_user!, only: %i[create destroy edit edit_forms instructions show update_forms]
      before_action :user_api_integrations, only: %i[edit edit_forms show]

      # (POST) create a PhoneSites API Key
      # /integrations/phone_sites/integration
      # integrations_phone_sites_integration_path
      # integrations_phone_sites_integration_url
      def create
        api_key_length = 36
        new_api_key = RandomCode.new.create(api_key_length)

        new_api_key = RandomCode.new.create(api_key_length) while UserApiIntegration.find_by(target: 'phone_sites', api_key: new_api_key)

        current_user.user_api_integrations.create(
          target:      'phone_sites',
          name:        'New Website',
          api_key:     new_api_key,
          live:        false,
          campaign_id: 0,
          form_fields: {}
        )

        user_api_integrations

        respond_to do |format|
          format.js { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[edit] } }
          format.html { redirect_to central_path }
        end
      end

      # (DELETE) destroy a PhoneSites API Key
      # /integrations/phone_sites/integration
      # integrations_phone_sites_integration_path
      # integrations_phone_sites_integration_url
      def destroy
        api_key = params.dig(:api_key).to_s

        if (user_api_integration = current_user.user_api_integrations.find_by(target: 'phone_sites', api_key:))
          user_api_integration.destroy
        end

        user_api_integrations

        respond_to do |format|
          format.js { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[edit] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) match PhoneSites Page form fields with internal fields
      # /integrations/phone_sites/integration/forms
      # integrations_phone_sites_integration_forms_edit_path
      # integrations_phone_sites_integration_forms_edit_url
      def edit_forms
        respond_to do |format|
          format.js { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[forms] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) PhoneSites integration configuration screen
      # /integrations/phone_sites/integration/edit
      # edit_integrations_phone_sites_integration_path
      # edit_integrations_phone_sites_integration_url
      def edit
        respond_to do |format|
          format.js { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[edit] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET/POST)
      # /integrations/phone_sites/integration/endpoint
      # integrations_phone_sites_integration_endpoint_path
      # integrations_phone_sites_integration_endpoint_url
      def endpoint
        sanitized_params = params.permit(:lead_id, :apiKey, :websiteName)
        api_key          = sanitized_params.dig(:apiKey).to_s
        lead_id          = sanitized_params.dig(:lead_id).to_s
        website_name     = sanitized_params.dig(:websiteName).to_s

        if api_key.present? && (user_api_integration = UserApiIntegration.find_by(target: 'phone_sites', api_key:))

          if user_api_integration.live
            # live mode / collect data

            internal_fields   = ::Webhook.internal_key_hash(user_api_integration.user.client, 'contact', %w[personal ext_references]).keys
            custom_field_keys = user_api_integration.user.client.client_custom_fields.pluck(:id)

            contact_data          = {}
            phone_numbers         = {}
            contact_custom_fields = {}
            emails                = []
            ok2                   = %w[ok2text ok2email]

            user_api_integration.form_fields.each do |ext_form_field, int_form_field|
              value = params.permit(ext_form_field.to_sym).dig(ext_form_field.to_sym).to_s

              unless value.empty?

                if internal_fields.include?(int_form_field)
                  emails << value if int_form_field == 'email'

                  if int_form_field == 'fullname'
                    fullname = value.to_s.parse_name
                    contact_data[:firstname] = fullname[:firstname]
                    contact_data[:lastname] = fullname[:lastname]
                  else
                    contact_data[int_form_field.to_sym] = value
                  end
                elsif custom_field_keys.include?(int_form_field.to_i)
                  contact_custom_fields[int_form_field.to_i] = value
                elsif int_form_field.include?('phone_')
                  phone_numbers[value.clean_phone(user_api_integration.user.client.primary_area_code)] = int_form_field.gsub('phone_', '')
                elsif ok2.include?(int_form_field)
                  contact_data[int_form_field.to_sym] = value.to_s.is_yes? ? 1 : 0
                end
              end
            end

            contact = Contact.find_or_initialize_by_phone_or_email_or_ext_ref(client_id: user_api_integration.user.client_id, phones: phone_numbers, emails:, ext_refs: { 'phone_sites' => lead_id })

            if contact.update(contact_data)
              # save any ContactCustomFields
              contact.update_custom_fields(custom_fields: contact_custom_fields) if contact_custom_fields.present?
              JsonLog.info 'Integrations::PhoneSites::IntegrationsController.endpoint', { last_form_keys: user_api_integration.last_form_keys.sort!, params: params.keys.sort! }

              if user_api_integration.campaign_id.positive? && user_api_integration.last_form_keys.sort! == params.keys.sort!
                # start new Campaign for the Contact
                Contacts::Campaigns::StartJob.perform_later(
                  campaign_id: user_api_integration.campaign_id,
                  client_id:   contact.client_id,
                  contact_id:  contact.id,
                  user_id:     contact.user_id
                )
              end
            end
          else
            # test mode / collect fields
            user_api_integration.update(form_fields: collect_field_params(user_api_integration:), name: website_name, last_form_keys: params.keys)
          end
        else
          JsonLog.info 'Integrations::PhoneSites::IntegrationsController.endpoint', { bad_or_missing_api_key: api_key }
        end

        render plain: 'Success', content_type: 'text/plain', status: :ok, layout: false
      end
      # example 01: phone_sites > submission
      # {
      # 	"lead_id"=>"leadUid123",
      # 	"email"=>"jordan@sendgrowth.com",
      # 	"page"=>"https://test.phonesites.com",
      # 	"apiKey"=>"x0dm0sYAmVNvM2wD0iWYNKOFyDnanfFW5aTb",
      # 	"websiteName"=>"Jordan Test",
      # 	"integration"=>{
      # 		"lead_id"=>"leadUid123",
      # 		"email"=>"jordan@sendgrowth.com",
      # 		"page"=>"https://test.phonesites.com",
      # 		"apiKey"=>"x0dm0sYAmVNvM2wD0iWYNKOFyDnanfFW5aTb",
      # 		"websiteName"=>"Jordan Test"
      # 	}
      # }

      # (GET) show instructions page for PhoneSites integration
      # /integrations/phone_sites/integration/instructions
      # integrations_phone_sites_integration_instructions_path
      # integrations_phone_sites_integration_instructions_url
      def instructions
        respond_to do |format|
          format.js { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[instructions] } }
          format.html { redirect_to central_path }
        end
      end

      # (GET) show PhoneSites integration
      # /integrations/phone_sites/integration
      # integrations_phone_sites_integration_path
      # integrations_phone_sites_integration_url
      def show
        respond_to do |format|
          format.js   { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[overview] } }
          format.html { render 'integrations/phone_sites/show' }
        end
      end

      # (POST) match PhoneSites Website fields with internal fields
      # /integrations/phone_sites/integration/forms
      # integrations_phone_sites_integration_forms_edit_path
      # integrations_phone_sites_integration_forms_edit_url
      def update_forms
        api_key = params.permit(:api_key).dig(:api_key)

        if api_key && (user_api_integration = current_user.user_api_integrations.find_by(target: 'phone_sites', api_key:))
          user_api_integration.update(
            form_fields: match_field_params(user_api_integration:),
            live:        params.permit(:live).dig(:live).to_bool,
            campaign_id: params.permit(:campaign_id).dig(:campaign_id).to_i
          )
        end

        user_api_integrations

        respond_to do |format|
          format.js { render partial: 'integrations/phone_sites/js/show', locals: { cards: %w[forms] } }
          format.html { redirect_to central_path }
        end
      end

      private

      def authorize_user!
        super

        return if current_user.access_controller?('integrations', 'user', session) && current_user.client.integrations_allowed.include?('phone_sites')

        sweetalert_error('Unathorized Access!', 'Your account is NOT authorized to access PhoneSites Integration. Please contact your account admin.', '', { persistent: 'OK' })

        respond_to do |format|
          format.js { render js: "window.location = '#{root_path}'" and return false }
          format.html { redirect_to root_path and return false }
        end
      end

      # collect field params from endpoint post
      # form_fields = collect_field_params( user_api_integration: UserApiIntegration )
      def collect_field_params(args)
        user_api_integration = args.dig(:user_api_integration)
        response             = user_api_integration.form_fields

        if user_api_integration.is_a?(UserApiIntegration)

          params.each_key do |form_field|
            response[form_field] ||= '' unless %w[lead_id apiKey pageName websiteName action controller integration ua page].include?(form_field)
          end
        end

        response
      end

      # match PhoneSites Website fields with internal fields
      # form_fields = match_field_params( user_api_integration: UserApiIntegration )
      def match_field_params(args)
        user_api_integration = args.dig(:user_api_integration)
        response             = user_api_integration.form_fields

        if user_api_integration.is_a?(UserApiIntegration)

          user_api_integration.form_fields.each do |ext_form_field, _int_form_field|
            response[ext_form_field] = params.require(:form_fields).permit(ext_form_field.to_sym).dig(ext_form_field.to_sym).to_s if params.include?(:form_fields)
          end
        end

        response
      end

      def user_api_integrations
        @user_api_integrations = current_user.user_api_integrations.where(target: 'phone_sites').order(:name)
      end
    end
  end
end
